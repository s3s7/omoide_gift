class GiftRecordsController < ApplicationController
  before_action :authenticate_user!, except: [ :index, :show ]
  before_action :set_gift_record, only: [ :show, :edit, :update, :destroy ]
  before_action :ensure_owner, only: [ :edit, :update, :destroy ]
  before_action :ensure_accessible, only: [ :show ]
  ## 設定したprepare_meta_tagsをprivateにあってもgiftrecordコントローラー以外にも使えるようにする
  helper_method :prepare_meta_tags
  before_action :setup_meta_tags, only: [ :show ]

  def index
    base_query = build_base_query
    @gift_records = apply_search_and_filters(base_query)

    calculate_statistics(base_query)
    apply_sorting_and_pagination
    prepare_share_confirmation_data
    prepare_pagination_params
    prepare_filter_options(base_query)
  end

  def my_index
    # ログインユーザーのすべてのギフト記録を表示
    unless user_signed_in?
      redirect_to new_user_session_path, alert: "ログインが必要です。"
      return
    end

    base_query = current_user.gift_records
    @gift_records = apply_search_and_filters_for_user(base_query)

    calculate_user_statistics(base_query)
    apply_sorting_and_pagination
    prepare_pagination_params
    prepare_user_filter_options(base_query)

    # エラーハンドリング
    rescue ActiveRecord::RecordNotFound
      redirect_to root_path, alert: "記録が見つかりませんでした。"
    rescue StandardError => e
      Rails.logger.error "My GiftRecords index error: #{e.message}"
      redirect_to root_path, alert: "データの取得中にエラーが発生しました。"
  end

  def private_index
    # ログインユーザーの非公開記録のみ表示
    unless user_signed_in?
      redirect_to new_user_session_path, alert: "ログインが必要です。"
      return
    end

    base_query = current_user.gift_records.where(is_public: false)

    # 関連テーブルの完全な事前読み込み（画像含む）
    @gift_records = base_query
      .includes(:gift_person, :event, :user, gift_person: :relationship, images_attachments: :blob)

    # 検索機能（オプション）
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      @gift_records = @gift_records.joins(:gift_person)
        .where(
          "gift_records.item_name ILIKE ? OR gift_records.memo ILIKE ? OR gift_people.name ILIKE ?",
          search_term, search_term, search_term
        )
    end

    # フィルタリング機能
    if params[:gift_person_id].present?
      @gift_records = @gift_records.where(gift_people_id: params[:gift_person_id])
    end

    if params[:relationship_id].present?
      @gift_records = @gift_records.joins(:gift_person).where(gift_people: { relationship_id: params[:relationship_id] })
    end

    if params[:event_id].present?
      @gift_records = @gift_records.where(event_id: params[:event_id])
    end

    if params[:date_from].present?
      @gift_records = @gift_records.where("gift_at >= ?", params[:date_from])
    end

    if params[:date_to].present?
      @gift_records = @gift_records.where("gift_at <= ?", params[:date_to])
    end

    # 統計情報用のカウント（並び替え前に計算）
    filtered_query = @gift_records
    @total_records = filtered_query.count

    @current_month_records = base_query.where(
      "gift_records.gift_at" => Date.current.beginning_of_month..Date.current.end_of_month
    ).count

    # ページサイズの決定（デバイス検出）
    per_page = if request.user_agent =~ /Mobile|Android|iPhone|iPad/
      12  # モバイル
    else
      15  # PC
    end

    # 並び替え処理
    sort_by = params[:sort_by].presence
    sort_order = params[:sort_order].presence == "asc" ? "asc" : "desc"

    if sort_by == "favorites"
      # お気に入り順 - ページネーションを考慮したソート処理
      # まず全レコードのIDを取得（ページネーション前）
      all_record_ids = @gift_records.pluck(:id)

      # レコードが存在しない場合は空のページネーション結果を返す
      if all_record_ids.empty?
        @gift_records = @gift_records.page(params[:page]).per(per_page)
      else
        # お気に入り数をハッシュで取得
        favorites_counts = Favorite
          .where(gift_record_id: all_record_ids)
          .group(:gift_record_id)
          .count

        # レコードをお気に入り数でソート
        sorted_ids = all_record_ids.sort_by do |id|
          count = favorites_counts[id] || 0
          sort_order == "desc" ? -count : count
        end

        # セキュリティ: IDが全て整数であることを確認
        validated_ids = sorted_ids.select { |id| id.is_a?(Integer) && id > 0 }

        if validated_ids.any?
          # ページネーション用にKaminariArrayを使用
          paginated_ids = Kaminari.paginate_array(validated_ids)
            .page(params[:page])
            .per(per_page)

          # 現在のページの記録のみを取得
          current_page_ids = paginated_ids.to_a
          if current_page_ids.any?
            # IDの順序を維持してレコードを取得
            records_hash = @gift_records.where(id: current_page_ids).index_by(&:id)
            sorted_records = current_page_ids.filter_map { |id| records_hash[id] }

            # Kaminari形式でラップして、ページネーション情報を保持
            @gift_records = Kaminari.paginate_array(
              sorted_records,
              total_count: validated_ids.length,
              limit: per_page,
              offset: paginated_ids.offset_value
            ).page(params[:page]).per(per_page)
          else
            @gift_records = @gift_records.page(params[:page]).per(per_page)
          end
        else
          @gift_records = @gift_records.none.page(params[:page]).per(per_page)
        end
      end
    elsif sort_by == "created_at"
      # 投稿日順
      @gift_records = @gift_records.order("gift_records.created_at #{sort_order}")
        .page(params[:page]).per(per_page)
    else
      # デフォルト：投稿日降順
      @gift_records = @gift_records.order(created_at: :desc)
        .page(params[:page]).per(per_page)
    end

    # フィルタリング用のオプション準備（実際に使われているギフト相手のみ）
    @gift_people_options = base_query
      .joins(:gift_person)
      .select("gift_people.name, gift_people.id")
      .where.not("gift_people.name" => [ nil, "" ])
      .distinct
      .order("gift_people.name")
      .pluck("gift_people.name", "gift_people.id")

    # 関係性オプション準備（実際に使われている関係性のみ）
    @relationship_options = base_query
      .joins(gift_person: :relationship)
      .select("relationships.name, relationships.id")
      .distinct
      .order("relationships.name")
      .pluck("relationships.name", "relationships.id")

    # イベントオプション準備（実際に使われているイベントのみ）
    @event_options = base_query
      .joins(:event)
      .select("events.name, events.id")
      .distinct
      .order("events.name")
      .pluck("events.name", "events.id")

    # ページネーション用の安全なパラメータを準備
    @pagination_params = pagination_params

    # エラーハンドリング
    rescue ActiveRecord::RecordNotFound
      redirect_to root_path, alert: "記録が見つかりませんでした。"
    rescue StandardError => e
      Rails.logger.error "Private GiftRecords index error: #{e.message}"
      redirect_to root_path, alert: "データの取得中にエラーが発生しました。"
  end

  def new
    @gift_record = GiftRecord.new(gift_direction: :given)
    @gift_people = current_user.gift_people.where.not(name: [ nil, "" ])
    prepare_events_for_form
    session[:gift_direction_default] = "given"
  end

  def new_received
    @gift_record = GiftRecord.new(gift_direction: :received)
    @gift_people = current_user.gift_people.where.not(name: [ nil, "" ])
    prepare_events_for_form
    session[:gift_direction_default] = "received"
  end

  def create
    # 新しいギフト相手を作成する場合
    if params[:gift_record][:gift_people_id] == "new"
      # gift_personパラメータが存在しない場合
      unless params[:gift_person].present?
        # gift_recordは一時的なオブジェクトとして作成（バリデーションは実行しない）
        @gift_record = GiftRecord.new(gift_record_params.except(:gift_people_id))
        apply_gift_direction_default(@gift_record)
        @gift_record.user = current_user
        @gift_people = current_user.gift_people.where.not(name: [ nil, "" ])
        prepare_events_for_form
        @gift_person = current_user.gift_people.build  # エラー表示用の空オブジェクト
        # ギフト相手のバリデーションのみ実行
        @gift_person.valid?
        render(@gift_record.received? ? :new_received : :new, status: :unprocessable_entity)
        return
      end

      # ギフト相手を先に作成（gift_record_idなし）
      @gift_person = current_user.gift_people.build(gift_person_params)

      if @gift_person.save
        # ギフト記録を作成してギフト相手と関連付け
        @gift_record = current_user.gift_records.build(gift_record_params.except(:gift_people_id))
        apply_gift_direction_default(@gift_record)
        @gift_record.gift_person = @gift_person

        if @gift_record.save
          flash_success(:created, item: GiftRecord.model_name.human)
          redirect_to gift_records_path(share_confirm: true, gift_record_id: @gift_record.id)
        else
          # ギフト記録の作成に失敗した場合、ギフト相手を削除
          @gift_person.destroy
          @gift_record = current_user.gift_records.build(gift_record_params.except(:gift_people_id))
          apply_gift_direction_default(@gift_record)
          @gift_people = current_user.gift_people.where.not(name: [ nil, "" ])
          prepare_events_for_form

          flash.now[:alert] = "ギフト記録の作成に失敗しました"
          render(@gift_record.received? ? :new_received : :new, status: :unprocessable_entity)
        end
      else
        # gift_recordは一時的なオブジェクトとして作成（バリデーションは実行しない）
        @gift_record = GiftRecord.new(gift_record_params.except(:gift_people_id))
        apply_gift_direction_default(@gift_record)
        @gift_record.user = current_user
        @gift_people = current_user.gift_people.where.not(name: [ nil, "" ])
        prepare_events_for_form

        # ギフト相手のバリデーションエラーをフォームで表示
        render(@gift_record.received? ? :new_received : :new, status: :unprocessable_entity)
      end
    else
      # 既存のギフト相手を選択する場合
      @gift_record = current_user.gift_records.build(gift_record_params)
      apply_gift_direction_default(@gift_record)
      if @gift_record.save
        flash_success(:created, item: GiftRecord.model_name.human)
        redirect_to gift_records_path(share_confirm: true, gift_record_id: @gift_record.id)
      else
        # エラー時のフォーム再表示用データ準備
        @gift_people = current_user.gift_people.where.not(name: [ nil, "" ])
        prepare_events_for_form
        render(@gift_record.received? ? :new_received : :new, status: :unprocessable_entity)
      end
    end
  end

  # もらったギフト用の作成エンドポイント（
  def create_received
    if params[:gift_record][:gift_people_id] == "new"
      unless params[:gift_person].present?
        @gift_record = GiftRecord.new(gift_record_params.except(:gift_people_id))
        @gift_record.gift_direction = :received
        @gift_record.user = current_user
        @gift_people = current_user.gift_people.where.not(name: [ nil, "" ])
        prepare_events_for_form
        @gift_person = current_user.gift_people.build
        @gift_person.valid?
        render :new_received, status: :unprocessable_entity
        return
      end

      @gift_person = current_user.gift_people.build(gift_person_params)

      if @gift_person.save
        @gift_record = current_user.gift_records.build(gift_record_params.except(:gift_people_id))
        @gift_record.gift_person = @gift_person
        @gift_record.gift_direction = :received

        if @gift_record.save
          flash_success(:created, item: GiftRecord.model_name.human)
          redirect_to gift_records_path(share_confirm: true, gift_record_id: @gift_record.id)
        else
          @gift_person.destroy
          @gift_record = current_user.gift_records.build(gift_record_params.except(:gift_people_id))
          @gift_record.gift_direction = :received
          @gift_people = current_user.gift_people.where.not(name: [ nil, "" ])
          prepare_events_for_form
          flash.now[:alert] = "ギフト記録の作成に失敗しました"
          render :new_received, status: :unprocessable_entity
        end
      else
        @gift_record = GiftRecord.new(gift_record_params.except(:gift_people_id))
        @gift_record.gift_direction = :received
        @gift_record.user = current_user
        @gift_people = current_user.gift_people.where.not(name: [ nil, "" ])
        prepare_events_for_form
        render :new_received, status: :unprocessable_entity
      end
    else
      @gift_record = current_user.gift_records.build(gift_record_params)
      @gift_record.gift_direction = :received

      if @gift_record.save
        flash_success(:created, item: GiftRecord.model_name.human)
        redirect_to gift_records_path(share_confirm: true, gift_record_id: @gift_record.id)
      else
        @gift_people = current_user.gift_people.where.not(name: [ nil, "" ])
        prepare_events_for_form
        render :new_received, status: :unprocessable_entity
      end
    end
  end

  def show
    # セキュリティ: set_gift_recordとensure_accessibleで処理済み
    # コメントも事前読み込み済み（set_gift_recordで処理）
    ## メタタグを設定する。
    # prepare_meta_tags(@gift_record)
  end

  def edit
    # セキュリティ: set_gift_recordとensure_ownerで処理済み
    @gift_people = current_user.gift_people.where.not(name: [ nil, "" ])
    prepare_events_for_form
  end

  def update
    # 削除対象画像の処理（バリデーション前に実行）
    delete_image_ids = params.dig(:gift_record, :delete_image_ids)
    if delete_image_ids.present?
      Rails.logger.debug "処理する削除対象画像ID: #{delete_image_ids.inspect}"

      delete_image_ids.each do |image_id|
        next if image_id.blank?

        Rails.logger.debug "削除対象画像ID: #{image_id}"

        # セキュリティ：この記録に属する画像かチェック
        image = @gift_record.images.find_by(id: image_id)
        if image
          Rails.logger.debug "画像を削除: #{image.id}"
          image.purge_later  # 非同期で削除（パフォーマンス向上）
        else
          Rails.logger.debug "削除対象画像が見つからない: #{image_id}"
        end
      end
    else
      Rails.logger.debug "削除対象画像なし"
    end

    # 新しい画像を取得（既存画像は保持するため、別途処理）
    new_images = params.dig(:gift_record, :images)
    Rails.logger.debug "New images: #{new_images.inspect}"

    # 画像以外のフィールドを更新（imagesとdelete_image_idsを除外）
    update_params = gift_record_params.except(:images, :delete_image_ids)
    Rails.logger.debug "Update params (without images): #{update_params.inspect}"

    if @gift_record.update(update_params)
      # 新しい画像がある場合のみ追加（既存画像は保持）
      if new_images.present?
        # 空の要素を除外して有効な画像のみを取得
        valid_new_images = new_images.select { |img| img.present? && img.respond_to?(:tempfile) }
        Rails.logger.debug "Valid new images count: #{valid_new_images.count}"

        if valid_new_images.any?
          # attachを使用して既存画像に追加
          @gift_record.images.attach(valid_new_images)
          Rails.logger.debug "新しい画像を追加しました"
        end
      end

      Rails.logger.debug "更新後の画像数: #{@gift_record.images.count}"
      flash_success(:updated, item: GiftRecord.model_name.human)
      redirect_to @gift_record
    else
      Rails.logger.debug "更新失敗: #{@gift_record.errors.full_messages}"
      @gift_people = current_user.gift_people.where.not(name: [ nil, "" ])
      prepare_events_for_form
      flash.now[:alert] = t("defaults.flash_message.not_updated", item: GiftRecord.model_name.human)
      render :edit, status: :unprocessable_entity
    end
  rescue StandardError => e
    Rails.logger.error "GiftRecord update error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    @gift_people = current_user.gift_people.where.not(name: [ nil, "" ])
    prepare_events_for_form
    flash.now[:alert] = "更新中にエラーが発生しました。再度お試しください。"
    render :edit, status: :unprocessable_entity
  end

  def destroy
    item_name = @gift_record.item_name.presence || "ギフト記録"

    if @gift_record.destroy
      flash[:notice] = "#{item_name}を削除しました。"
      redirect_to gift_records_path
    else
      flash[:alert] = "削除に失敗しました。再度お試しください。"
      redirect_to gift_records_path
    end
  rescue StandardError => e
    Rails.logger.error "GiftRecord deletion error: #{e.message}"
    flash[:alert] = "削除中にエラーが発生しました。"
    redirect_to gift_records_path
  end

  # オートコンプリート用API
  def autocomplete
    query = params[:q]&.strip

    if query.present? && query.length >= 1
      search_term = "%#{query}%"

      # みんなのギフト画面：公開記録のみ検索対象
      base_query = GiftRecord.where(is_public: true)

      # アイテム名検索結果
      item_results = base_query
        .includes(:gift_person, :user, gift_person: :relationship)
        .where("gift_records.item_name ILIKE ?", search_term)
        .limit(4)
        .map do |record|
          {
            id: record.id,
            item_name: record.item_name,
            type: "item",
            display_text: record.item_name,
            search_highlight: highlight_match(record.item_name, query)
          }
        end

      # メモ検索結果
      memo_results = base_query
        .includes(:gift_person, :user, gift_person: :relationship)
        .where.not(memo: [ nil, "" ])
        .where("gift_records.memo ILIKE ?", search_term)
        .limit(3)
        .map do |record|
          {
            id: record.id,
            item_name: record.item_name,
            type: "memo",
            display_text: "#{record.item_name} (メモ: #{truncate_text(record.memo, 15)})",
            search_highlight: highlight_match(record.memo, query)
          }
        end

      results = (item_results + memo_results).uniq { |item| item[:id] }.take(8)

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
    Rails.logger.error "GiftRecords autocomplete error: #{e.message}"
    render json: {
      results: [],
      total_count: 0,
      error: "検索中にエラーが発生しました"
    }, status: :internal_server_error
  end

  # シェア拒否を記録
  def dismiss_share
    unless user_signed_in?
      render json: { success: false, error: "Authentication required" }, status: :unauthorized
      return
    end

    gift_record_id = params[:gift_record_id]

    if gift_record_id.present?
      # 指定されたギフト記録が現在のユーザーのものかチェック
      gift_record = current_user.gift_records.find_by(id: gift_record_id)
      unless gift_record
        render json: { success: false, error: "Gift record not found" }, status: :not_found
        return
      end

      # セッションに拒否したギフト記録IDを保存
      session[:dismissed_share_records] ||= []
      session[:dismissed_share_records] << gift_record_id.to_s
      session[:dismissed_share_records].uniq!

      render json: { success: true }
    else
      render json: { success: false, error: "Invalid gift record ID" }, status: :bad_request
    end
  rescue StandardError => e
    render json: { success: false, error: "Internal server error" }, status: :internal_server_error
  end


  private

  def build_base_query
    GiftRecord.where(is_public: true)
      .includes(:gift_person, :event, :user, gift_person: :relationship, images_attachments: :blob)
  end

  def apply_search_and_filters(base_query)
    result = base_query

    # 検索機能
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      result = result.joins(:gift_person)
        .where(
          "gift_records.item_name ILIKE ? OR gift_records.memo ILIKE ? OR gift_people.name ILIKE ?",
          search_term, search_term, search_term
        )
    end

    # フィルタリング機能
    result = apply_filters(result)
    result
  end

  def apply_filters(query)
    query = query.where(gift_people_id: params[:gift_person_id]) if params[:gift_person_id].present?

    if params[:relationship_id].present?
      query = query.joins(:gift_person).where(gift_people: { relationship_id: params[:relationship_id] })
    end

    query = query.where(event_id: params[:event_id]) if params[:event_id].present?
    query = query.where("gift_at >= ?", params[:date_from]) if params[:date_from].present?
    query = query.where("gift_at <= ?", params[:date_to]) if params[:date_to].present?

    query
  end

  def calculate_statistics(base_query)
    @total_records = @gift_records.count
    @current_month_records = base_query.where(
      "gift_records.gift_at" => Date.current.beginning_of_month..Date.current.end_of_month
    ).count
  end

  def per_page_count
    @per_page_count ||= if request.user_agent =~ /Mobile|Android|iPhone|iPad/
      12  # モバイル
    else
      15  # PC
    end
  end

  def apply_sorting_and_pagination
    sort_by = params[:sort_by].presence
    sort_order = params[:sort_order].presence == "asc" ? "asc" : "desc"

    case sort_by
    when "favorites"
      apply_favorites_sorting(sort_order)
    when "created_at"
      @gift_records = @gift_records.order("gift_records.created_at #{sort_order}")
        .page(params[:page]).per(per_page_count)
    else
      @gift_records = @gift_records.order(created_at: :desc)
        .page(params[:page]).per(per_page_count)
    end
  end

  def apply_favorites_sorting(sort_order)
    all_record_ids = @gift_records.pluck(:id)

    if all_record_ids.empty?
      @gift_records = @gift_records.page(params[:page]).per(per_page_count)
      return
    end

    # お気に入り数を取得
    favorites_counts = Favorite
      .where(gift_record_id: all_record_ids)
      .group(:gift_record_id)
      .count

    # ソート処理
    sorted_ids = all_record_ids.sort_by do |id|
      count = favorites_counts[id] || 0
      sort_order == "desc" ? -count : count
    end

    # セキュリティチェック
    validated_ids = sorted_ids.select { |id| id.is_a?(Integer) && id > 0 }

    if validated_ids.any?
      paginate_sorted_records(validated_ids)
    else
      @gift_records = @gift_records.none.page(params[:page]).per(per_page_count)
    end
  end

  def paginate_sorted_records(validated_ids)
    paginated_ids = Kaminari.paginate_array(validated_ids)
      .page(params[:page])
      .per(per_page_count)

    current_page_ids = paginated_ids.to_a

    if current_page_ids.any?
      records_hash = @gift_records.where(id: current_page_ids).index_by(&:id)
      sorted_records = current_page_ids.filter_map { |id| records_hash[id] }

      @gift_records = Kaminari.paginate_array(
        sorted_records,
        total_count: validated_ids.length,
        limit: per_page_count,
        offset: paginated_ids.offset_value
      ).page(params[:page]).per(per_page_count)
    else
      @gift_records = @gift_records.page(params[:page]).per(per_page_count)
    end
  end

  def prepare_share_confirmation_data
    return unless user_signed_in? && params[:share_confirm] == "true" && params[:gift_record_id].present?

    gift_record_id = params[:gift_record_id].to_s
    dismissed_records = session[:dismissed_share_records] || []

    unless dismissed_records.include?(gift_record_id)
      @share_gift_record = current_user.gift_records
        .includes(:gift_person, :event, gift_person: :relationship)
        .find_by(id: params[:gift_record_id])
    end
  end

  def prepare_pagination_params
    @pagination_params = pagination_params
  end

  def gift_record_params
    params.require(:gift_record).permit(
      :title, :description, :body,
      :gift_people_id, :memo, :item_name, :amount, :gift_at, :event_id, :is_public, :commentable,
      :gift_item_category_id, :gift_direction, images: [], delete_image_ids: []
    )
  end

  def gift_person_params
    params.require(:gift_person).permit(:name, :relationship_id, :birthday, :likes, :dislikes, :address, :memo)
  end

  # セキュリティ: ギフト記録を取得
  def set_gift_record
    if action_name == "show"
      # show アクション：公開記録または自分の記録
      if user_signed_in?
        @gift_record = GiftRecord.where("gift_records.is_public = ? OR gift_records.user_id = ?", true, current_user.id)
          .includes(:gift_person, :event, :user, gift_person: :relationship, comments: :user)
          .find(params[:id])
      else
        @gift_record = GiftRecord.where("gift_records.is_public = ?", true)
          .includes(:gift_person, :event, :user, gift_person: :relationship, comments: :user)
          .find(params[:id])
      end
    else
      # edit, update, destroy アクション：自分の記録のみ
      @gift_record = current_user.gift_records
        .includes(:gift_person, :event, gift_person: :relationship)
        .find(params[:id])
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to gift_records_path, alert: "指定されたギフト記録が見つかりません。"
  end

  # セキュリティ: 所有者確認
  def ensure_owner
    unless @gift_record&.user == current_user
      redirect_to gift_records_path, alert: "アクセス権限がありません。"
    end
  end

  # セキュリティ: 閲覧権限確認（公開記録または自分の記録）
  def ensure_accessible
    return if @gift_record.is_public? || (user_signed_in? && @gift_record.user == current_user)

    redirect_to gift_records_path, alert: "この記録は非公開です。"
  end

  # ページネーション用の安全なパラメータ
  def pagination_params
    params.permit(
      :search,
      :gift_person_id,
      :relationship_id,
      :event_id,
      :date_from,
      :date_to,
      :sort_by,
      :sort_order,
      :filter_type,
      :filter_value
    ).to_h
  end

  # イベント選択肢の準備
  def prepare_events_for_form
    @events = Event.all.order(:name)
    @popular_events = Event.joins(:gift_records)
      .group("events.id")
      .order("COUNT(gift_records.id) DESC")
      .limit(5)
  end

  # gift_directionが未指定の場合に、新規画面の種別に基づいて自動設定
  def apply_gift_direction_default(record)
    return if record.gift_direction.present?

    default = session[:gift_direction_default]
    record.gift_direction = (default == "received") ? :received : :given
  end

  # オートコンプリート用ヘルパーメソッド
  def highlight_match(text, query)
    return text unless text.present? && query.present?

    text.gsub(Regexp.new(Regexp.escape(query), Regexp::IGNORECASE)) do |match|
      "<mark>#{match}</mark>"
    end
  rescue StandardError
    text
  end

  def truncate_text(text, length = 20)
    return "" unless text.present?

    text.length > length ? "#{text[0..length-1]}..." : text
  end

  # def prepare_meta_tags(gift_record)
  #   return unless gift_record

  #   # アイテム名をOGP画像のテキストに使用
  #   ogp_text = gift_record.item_name.presence || "ギフト記録"
  #   image_url = "#{request.base_url}/images/ogp.png?text=#{CGI.escape(ogp_text)}"
  #   page_title = "#{gift_record.item_name} - ギフト記録"

  #   # メタタグを設定
  #   set_meta_tags title: page_title,
  #                 og: {
  #                   site_name: 'おもいでギフト',
  #                   title: page_title,
  #                   type: 'article',
  #                   url: request.original_url,
  #                   image: image_url,
  #                   image_width: 1200,
  #                   image_height: 630,
  #                   locale: 'ja_JP'
  #                 },
  #                 twitter: {
  #                   card: 'summary_large_image',
  #                   title: page_title,
  #                   image: image_url
  #                 }
  # end
  # def prepare_meta_tags(gift_record)
  #   return unless gift_record

  #   ## このimage_urlにMiniMagickで設定したOGPの生成した合成画像を代入する
  #   image_url = "#{request.base_url}/images/ogp.png?text=#{CGI.escape(gift_record.item_name)}"
  #   page_title = "#{gift_record.item_name} - ギフト記録"
  #   page_description = "#{gift_record.item_name}のギフト記録です。"

  #   set_meta_tags title: page_title,
  #                 description: page_description,
  #                 og: {
  #                   site_name: "思い出ギフト",
  #                   title: page_title,
  #                   description: page_description,
  #                   type: "website",
  #                   url: request.original_url,
  #                   image: image_url,
  #                   image_width: 1200,
  #                   image_height: 630,
  #                   locale: "ja_JP"
  #                 },
  #                 twitter: {
  #                   card: "summary_large_image",
  #                   title: page_title,
  #                   description: page_description,
  #                   image: image_url
  #                 }
  # end

  def prepare_meta_tags(gift_record)
  return unless gift_record

  # OGP画像: ActiveStorageの画像優先、なければ動的生成をS3保存
  image_url = gift_record.ogp_image_url(request)
  secure_image_url = image_url.present? ? image_url.to_s.sub(%r{^http://}, "https://") : nil
  page_title = build_page_title(gift_record)
  page_description = build_page_description(gift_record)
  p "!!!!!!image_url:#{image_url}"
  set_meta_tags title: page_title,
                description: page_description,
                canonical: request.original_url,
                keywords: build_keywords(gift_record),
                 og: {
                  site_name: "思い出ギフト",
                  title: page_title,
                  description: page_description,
                  type: "website",
                  url: request.original_url,
                  image: image_url,
                  image_secure_url: image_url,
                  image_width: 1200,
                  image_height: 630,
                  locale: "ja_JP"
                },
                twitter: {
                  card: "summary_large_image",
                  site: "@your_twitter_handle", # Twitterアカウントがあれば
                  title: page_title,
                  description: page_description,
                  image: image_url
                }
end

 


private

def setup_meta_tags
    description = "#{@gift_record.item_name}のギフト記録です。"
    title =  "#{@gift_record.item_name} - 思い出ギフト"

    set_meta_tags(
      title: title,
      description: description,
      og: {
        title: title,
        description: description,
        image: gift_record_image_url(@gift_record),
        url: request.original_url,
        type: "article"
      },
      twitter: {
        card: "summary_large_image",
        title: title,
        description: description,
        image: gift_record_image_url(@gift_record)
      }
    )
  end


#  def gift_record_image_url(gift_record)
#     if gift_record.images.attached?
#       p "!!!!!!gift_record_image_url "
#       Rails.application.routes.url_helpers.rails_blobs_url(
#         gift_record.images,
#         host: request.host_with_port,
#         protocol: request.protocol
#       )
#     else
#         p "!!!!!!gift_record_image_url view_context"
      
#       view_context.image_url("ogp.png")
#     end
#   end

def gift_record_image_url(gift_record)
  Rails.logger.info "=== gift_record_image_url Debug ==="
  Rails.logger.info "gift_record: #{gift_record.inspect}"
  
  # nilチェック
  if gift_record.nil?
    Rails.logger.info "gift_record is nil, using default image"
    return view_context.image_url("ogp.png")
  end
  
  # 画像が添付されているかチェック
  if gift_record.images.attached? && gift_record.images.any?
    Rails.logger.info "Images attached: #{gift_record.images.count} images"
    
    begin
      first_image = gift_record.images.first
      Rails.logger.info "First image blob: #{first_image.blob.filename}"
      
      # url_forを使用（最も安全）
      url = url_for(first_image)
      Rails.logger.info "Generated URL: #{url}"
      
      return url
    rescue => e
      Rails.logger.error "Error generating image URL: #{e.class} - #{e.message}"
      Rails.logger.error e.backtrace.first(3).join("\n")
    end
  else
    Rails.logger.info "No images attached or images array is empty"
  end
  
  # フォールバック
  Rails.logger.info "Using default image"
  view_context.image_url("ogp.png")
end


def generate_ogp_image_url(gift_record)
  return default_ogp_image_url unless gift_record&.item_name.present?

  begin
    "#{request.base_url}/images/ogp.png?text=#{CGI.escape(gift_record.item_name)}"
  rescue => e
    Rails.logger.error "OGP URL生成エラー: #{e.message}"
    default_ogp_image_url
  end
end

def build_page_title(gift_record)
  "#{gift_record.item_name} - 思い出ギフト"
end

def build_page_description(gift_record)
  base_description = "#{gift_record.item_name}のギフト記録です。"

  # より詳細な説明を追加
  if gift_record.item_name.present?
    base_description = "#{gift_record.item_name}からいただいた#{base_description}"
  end

  if gift_record.item_name.present?
    base_description += " #{gift_record.item_name.truncate(50)}"
  end

  base_description
end

  def build_keywords(gift_record)
    keywords = [ "ギフト", "プレゼント", "記録", "思い出" ]
    keywords << gift_record.item_name if gift_record.item_name.present?
    keywords.join(",")
  end

  def default_ogp_image_url
    url = "#{request.base_url}#{image_path('ogp.png')}"
    Rails.env.production? ? url.sub(%r{^http://}, "https://") : url
  end

  def prepare_filter_options(base_query)
    @relationship_options = build_relationship_options(base_query)
    @event_options = build_event_options(base_query)
  end

  def build_relationship_options(base_query)
    base_query
      .joins(gift_person: :relationship)
      .group("relationships.id, relationships.name")
      .order("relationships.name")
      .pluck("relationships.name", "relationships.id")
  end

  def build_event_options(base_query)
    base_query
      .joins(:event)
      .group("events.id, events.name")
      .order("events.name")
      .pluck("events.name", "events.id")
  end

  def apply_search_and_filters_for_user(base_query)
    result = base_query
      .includes(:gift_person, :event, :user, gift_person: :relationship, images_attachments: :blob)

    # 検索機能
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      result = result.joins(:gift_person)
        .where(
          "gift_records.item_name ILIKE ? OR gift_records.memo ILIKE ? OR gift_people.name ILIKE ?",
          search_term, search_term, search_term
        )
    end

    # フィルタリング機能
    result = apply_filters(result)
    result
  end

  def calculate_user_statistics(base_query)
    @total_records = @gift_records.count
    @current_month_records = base_query.where(
      "gift_records.gift_at" => Date.current.beginning_of_month..Date.current.end_of_month
    ).count
    @public_records_count = base_query.where(is_public: true).count
    @private_records_count = base_query.where(is_public: false).count
  end

  def prepare_user_filter_options(base_query)
    @gift_people_options = build_user_gift_people_options(base_query)
    @relationship_options = build_relationship_options(base_query)
    @event_options = build_event_options(base_query)
  end

  def build_user_gift_people_options(base_query)
    base_query
      .joins(:gift_person)
      .group("gift_people.id, gift_people.name")
      .where.not("gift_people.name" => [ nil, "" ])
      .order("gift_people.name")
      .pluck("gift_people.name", "gift_people.id")
  end
end
