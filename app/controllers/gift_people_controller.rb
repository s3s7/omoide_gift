class GiftPeopleController < ApplicationController
  before_action :authenticate_user!
  before_action :set_gift_person, only: [ :show, :edit, :update, :destroy ]
  before_action :ensure_owner, only: [ :show, :edit, :update, :destroy ]

  def index
    @gift_people = current_user.gift_people
      .includes(:relationship)
      .where.not(name: [ nil, "" ])

    # 検索機能
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      @gift_people = @gift_people.where(
        "gift_people.name ILIKE ? OR gift_people.memo ILIKE ? OR gift_people.likes ILIKE ? OR gift_people.dislikes ILIKE ?",
        search_term, search_term, search_term, search_term
      )
    end

    # 関係性でフィルタリング
    if params[:relationship_id].present?
      @gift_people = @gift_people.where(relationship_id: params[:relationship_id])
    end

    # イベントでフィルタリング（ギフト記録経由）
    if params[:event_id].present?
      @gift_people = @gift_people.joins(:gift_records).where(gift_records: { event_id: params[:event_id] }).distinct
    end

    # 統計情報用のカウント（並び替え前に計算）
    @total_people = @gift_people.count

    # 並び替え処理
    sort_by = params[:sort_by].presence
    sort_order = params[:sort_order].presence || "desc"

    if sort_by == "gift_records_count"
      # ギフト記録数順
      @gift_people = @gift_people
        .left_joins(:gift_records)
        .group("gift_people.id")
        .order("COUNT(gift_records.id) #{sort_order}, gift_people.name #{sort_order}")
    else
      # デフォルト：名前順
      @gift_people = @gift_people.order(:name)
    end

    # フィルタリング用のオプション準備
    @relationship_options = current_user.gift_people
      .joins(:relationship)
      .select("relationships.name, relationships.id")
      .distinct
      .order("relationships.name")
      .pluck("relationships.name", "relationships.id")

    # イベントオプション準備（ギフト記録経由で実際に使われているイベントのみ）
    @event_options = current_user.gift_people
      .joins(:gift_records)
      .joins("INNER JOIN events ON gift_records.event_id = events.id")
      .select("events.name, events.id")
      .distinct
      .order("events.name")
      .pluck("events.name", "events.id")

  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "データが見つかりませんでした。"
  rescue StandardError => e
    Rails.logger.error "GiftPeople index error: #{e.message}"
    redirect_to root_path, alert: "データの取得中にエラーが発生しました。"
  end

  # オートコンプリート用API
  def autocomplete
    query = params[:q]&.strip

    if query.present? && query.length >= 1
      search_term = "%#{query}%"

      # 名前検索結果
      name_results = current_user.gift_people
        .includes(:relationship)
        .where.not(name: [ nil, "" ])
        .where("gift_people.name ILIKE ?", search_term)
        .limit(5)
        .map do |person|
          {
            id: person.id,
            name: person.name,
            relationship: person.relationship&.name || "未設定",
            type: "name",
            display_text: person.name,
            search_highlight: highlight_match(person.name, query)
          }
        end

      # 好きなもの検索結果
      likes_results = current_user.gift_people
        .includes(:relationship)
        .where.not(name: [ nil, "" ])
        .where.not(likes: [ nil, "" ])
        .where("gift_people.likes ILIKE ?", search_term)
        .limit(3)
        .map do |person|
          {
            id: person.id,
            name: person.name,
            relationship: person.relationship&.name || "未設定",
            type: "likes",
            display_text: "#{person.name} (好き: #{truncate_text(person.likes, 20)})",
            search_highlight: highlight_match(person.likes, query)
          }
        end

      # メモ検索結果
      memo_results = current_user.gift_people
        .includes(:relationship)
        .where.not(name: [ nil, "" ])
        .where.not(memo: [ nil, "" ])
        .where("gift_people.memo ILIKE ?", search_term)
        .limit(3)
        .map do |person|
          {
            id: person.id,
            name: person.name,
            relationship: person.relationship&.name || "未設定",
            type: "memo",
            display_text: "#{person.name} (メモ: #{truncate_text(person.memo, 20)})",
            search_highlight: highlight_match(person.memo, query)
          }
        end

      results = (name_results + likes_results + memo_results).uniq { |item| item[:id] }.take(8)

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
      .limit(5)
  end

  def new
    @gift_person = current_user.gift_people.build
    prepare_relationships_for_form
  end

  def create
    @gift_person = current_user.gift_people.build(gift_person_params)

    if @gift_person.save
      flash_success(:created, item: "ギフト相手「#{@gift_person.name}」")
      redirect_to gift_people_path
    else
      prepare_relationships_for_form
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
    params.require(:gift_person).permit(:name, :relationship_id, :birthday, :likes, :dislikes, :memo, :avatar, :remove_avatar)
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

  def truncate_text(text, length = 20)
    return "" unless text.present?

    text.length > length ? "#{text[0..length-1]}..." : text
  end
end
