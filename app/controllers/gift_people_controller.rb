class GiftPeopleController < ApplicationController
  MIN_QUERY_LENGTH = 1
  NAME_RESULTS_LIMIT = 5
  SECONDARY_RESULTS_LIMIT = 3
  COMBINED_RESULTS_LIMIT = 8
  TRUNCATE_DEFAULT_LENGTH = 20
  MOBILE_PER_PAGE = 12
  DESKTOP_PER_PAGE = 15

  before_action :authenticate_user!
  before_action :set_gift_person, only: [ :show, :edit, :update, :destroy ]
  before_action :ensure_owner, only: [ :show, :edit, :update, :destroy ]

  def index
  @gift_people = build_base_query
  apply_search_and_filters
  calculate_statistics
  apply_sorting_and_pagination
  prepare_filter_options
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "データが見つかりませんでした。"
  rescue StandardError => e
    Rails.logger.error "GiftPeople index error: #{e.message}"
    redirect_to root_path, alert: "データの取得中にエラーが発生しました。"
  end

  # オートコンプリート用API
  def autocomplete
    query = params[:q]&.strip

    if query.present? && query.length >= MIN_QUERY_LENGTH
      search_term = "%#{query}%"

      # 名前検索結果
      name_results = current_user.gift_people
        .includes(:relationship)
        .where.not(name: [ nil, "" ])
        .where("gift_people.name ILIKE ?", search_term)
        .limit(NAME_RESULTS_LIMIT)
        .map do |person|
          {
            id: person.id,
            name: person.name,
            relationship: person.relationship&.name || "未設定",
            type: "name",
            display_text: person.name,
            input_text: person.name,
            search_highlight: highlight_match(person.name, query)
          }
        end

      # 好きなもの検索結果
      likes_results = current_user.gift_people
        .includes(:relationship)
        .where.not(name: [ nil, "" ])
        .where.not(likes: [ nil, "" ])
        .where("gift_people.likes ILIKE ?", search_term)
        .limit(SECONDARY_RESULTS_LIMIT)
        .map do |person|
          {
            id: person.id,
            name: person.name,
            relationship: person.relationship&.name || "未設定",
            type: "likes",
            display_text: "#{person.name} (好き: #{truncate_text(person.likes, TRUNCATE_DEFAULT_LENGTH)})",
            input_text: person.likes.to_s,
            search_highlight: highlight_match(person.likes, query)
          }
        end

      # メモ検索結果
      memo_results = current_user.gift_people
        .includes(:relationship)
        .where.not(name: [ nil, "" ])
        .where.not(memo: [ nil, "" ])
        .where("gift_people.memo ILIKE ?", search_term)
        .limit(SECONDARY_RESULTS_LIMIT)
        .map do |person|
          {
            id: person.id,
            name: person.name,
            relationship: person.relationship&.name || "未設定",
            type: "memo",
            display_text: "#{person.name} (メモ: #{truncate_text(person.memo, TRUNCATE_DEFAULT_LENGTH)})",
            input_text: person.memo.to_s,
            search_highlight: highlight_match(person.memo, query)
          }
        end

      results = (name_results + likes_results + memo_results).uniq { |item| item[:id] }.take(COMBINED_RESULTS_LIMIT)

      render json: {
        results: results,
        total_count: results.length
      }
    else
      render json: {
        results: [],
        total_count: 0
      }
    end

  rescue StandardError => e
    Rails.logger.error "GiftPeople autocomplete error: #{e.message}"
    render json: {
      results: [],
      total_count: 0,
      error: "検索中にエラーが発生しました"
    }, status: :internal_server_error
  end

  def show
    # セキュリティ: set_gift_personとensure_ownerで処理済み
    @gift_records = @gift_person.user.gift_records
      .where(gift_people_id: @gift_person.id)
      .includes(:event)
      .order(gift_at: :desc)
      .limit(NAME_RESULTS_LIMIT)
  end

  def new
    @gift_person = current_user.gift_people.build
    @line_connected = current_user.line_connected?
    @remind_form_values = {}
    @remind_form_enabled = false
    prepare_relationships_for_form
    prepare_remind_for_form
  end

  def create
    @line_connected = current_user.line_connected?
    @gift_person = current_user.gift_people.build(gift_person_params)
    @remind_form_values = permitted_remind_params.to_h.transform_values { |value| value.presence }
    @remind_form_enabled = remind_form_enabled?(@remind_form_values)
    @remind_form_enabled &&= @line_connected
    prepare_remind_for_form

    success = true

    ActiveRecord::Base.transaction do
    success &&= @gift_person.save

    if success && @remind_form_enabled
      success &&= build_and_save_remind_for(@gift_person, @remind_form_values)
    end

      raise ActiveRecord::Rollback unless success
    end

    if success
      flash_success(:created, item: "ギフト相手「#{@gift_person.name}」")
      redirect_to gift_people_path
    else
      prepare_relationships_for_form
      prepare_remind_for_form
      @remind_form_enabled = true if @remind&.errors&.any?
      flash.now[:alert] = "ギフト相手の作成に失敗しました。"
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    # セキュリティ: set_gift_personとensure_ownerで処理済み
    prepare_relationships_for_form
  end

  def update
    # アバター削除の処理
    if params[:gift_person][:remove_avatar] == "1"
      @gift_person.avatar.purge if @gift_person.avatar.attached?
    end

    # remove_avatarパラメータを除いてアップデート
    update_params = gift_person_params
    update_params.delete(:remove_avatar)

    if @gift_person.update(update_params)
      flash_success(:updated, item: "ギフト相手「#{@gift_person.name}」")
      redirect_to @gift_person
    else
      prepare_relationships_for_form
      flash.now[:alert] = "更新に失敗しました。"
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    name = @gift_person.name
    if @gift_person.destroy
      flash[:notice] = "ギフト相手「#{name}」を削除しました。"
      redirect_to gift_people_path
    else
      flash[:alert] = "削除に失敗しました。再度お試しください。"
      redirect_to gift_people_path
    end
  rescue StandardError => e
    Rails.logger.error "GiftPerson deletion error: #{e.message}"
    flash[:alert] = "削除中にエラーが発生しました。"
    redirect_to gift_people_path
  end

  private

  def gift_person_params
    params.require(:gift_person).permit(:name, :relationship_id, :birthday, :likes, :dislikes, :address, :memo, :avatar, :remove_avatar)
  end

  def set_gift_person
    @gift_person = current_user.gift_people
      .includes(:relationship)
      .find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to gift_people_path, alert: "指定されたギフト相手が見つかりません。"
  end

  def ensure_owner
    unless @gift_person&.user == current_user
      redirect_to gift_people_path, alert: "アクセス権限がありません。"
    end
  end

  def prepare_relationships_for_form
    @relationships = Relationship.active.ordered
  end

  def prepare_remind_for_form
    @remind_form_values ||= {}
    @remind ||= current_user.reminds.build
    if @remind_form_values.present?
      @remind.notification_at = @remind_form_values[:notification_at]
    end
    @remindable_gift_people = current_user.gift_people.includes(:relationship).order(:name)
    if @line_connected && @remind&.errors&.any?
      @remind_form_enabled = true
    end
  end

  def permitted_remind_params
    if params[:remind].present?
      params.require(:remind).permit(:notification_at, :notification_days_before, :notification_time)
    elsif params.dig(:gift_person, :remind).present?
      params.require(:gift_person).require(:remind).permit(:notification_at, :notification_days_before, :notification_time)
    else
      {}
    end
  end

  def remind_form_enabled?(values)
    values.values.compact.any?
  end

  def build_and_save_remind_for(gift_person, values)
    @remind.gift_person = gift_person
    @remind.notification_at = values[:notification_at]

    days_before = values[:notification_days_before]
    time_str = values[:notification_time]

    if days_before.blank? || time_str.blank?
      @remind.errors.add(:base, "通知日数と通知時刻を設定してください")
      return false
    end

    unless @remind.set_notification_sent_at(days_before, time_str)
      return false
    end

    @remind.save
  end

  # オートコンプリート用ヘルパーメソッド
  def highlight_match(text, query)
    return ERB::Util.html_escape(text) unless text.present? && query.present?

    escaped_text = ERB::Util.html_escape(text)
    escaped_query = ERB::Util.html_escape(query)

    escaped_text.gsub(Regexp.new(Regexp.escape(escaped_query), Regexp::IGNORECASE)) do |match|
      "<mark>#{match}</mark>"
    end.html_safe
  rescue StandardError
    ERB::Util.html_escape(text)
  end

  def truncate_text(text, length = TRUNCATE_DEFAULT_LENGTH)
    return "" unless text.present?

    text.length > length ? "#{text[0..length-1]}..." : text
  end

  # ページネーション用の安全なパラメータ
  def gift_people_pagination_params
    params.permit(
      :search,
      :relationship_id,
      :event_id,
      :sort_by,
      :sort_order
    ).to_h
  end

  def build_base_query
    current_user.gift_people
      .includes(:relationship)
      .where.not(name: [ nil, "" ])
  end

  def apply_search_and_filters
    # 検索機能
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      @gift_people = @gift_people.where(
        "gift_people.name ILIKE ? OR gift_people.memo ILIKE ? OR gift_people.likes ILIKE ? OR gift_people.dislikes ILIKE ?",
        search_term, search_term, search_term, search_term
      )
    end

    # 関係性でフィルタリング
    @gift_people = @gift_people.where(relationship_id: params[:relationship_id]) if params[:relationship_id].present?

    # イベントでフィルタリング（ギフト記録経由）
    if params[:event_id].present?
      @gift_people = @gift_people.joins(:gift_records)
        .where(gift_records: { event_id: params[:event_id] })
        .distinct
    end
  end

  def calculate_statistics
    @total_people = @gift_people.count
  end

  def per_page_count
    @per_page_count ||= if request.user_agent =~ /Mobile|Android|iPhone|iPad/
      MOBILE_PER_PAGE
    else
      DESKTOP_PER_PAGE
    end
  end

  def apply_sorting_and_pagination
    sort_by = params[:sort_by].presence
    sort_order = params[:sort_order].presence || "desc"

    case sort_by
    when "gift_records_count"
      @gift_people = @gift_people
        .left_joins(:gift_records)
        .select("gift_people.*, COUNT(gift_records.id) as gift_records_count")
        .group("gift_people.id")
        .order("gift_records_count #{sort_order}, gift_people.name #{sort_order}")
        .page(params[:page]).per(per_page_count)
    else
      # デフォルト：名前順
      @gift_people = @gift_people.order(:name)
        .page(params[:page]).per(per_page_count)
    end

    @pagination_params = gift_people_pagination_params
  end

  def prepare_filter_options
    @relationship_options = build_relationship_options
    @event_options = build_event_options
  end

  def build_relationship_options
    # サブクエリで現在ユーザーに紐づく関係性IDを一意に抽出し、
    # Relationship側でposition順に取得する（DB方言差異の影響を避ける）
    rel_ids = current_user.gift_people.select('DISTINCT relationship_id')
    Relationship.where(id: rel_ids).ordered.pluck(:name, :id)
  end

  def build_event_options
    event_ids = current_user.gift_people
      .joins(:gift_records)
      .select('DISTINCT gift_records.event_id')
    Event.where(id: event_ids).order(:name).pluck(:name, :id)
  end
end
