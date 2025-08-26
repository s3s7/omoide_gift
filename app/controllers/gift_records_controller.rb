class GiftRecordsController < ApplicationController
  before_action :authenticate_user!, except: [ :index, :show ]
  before_action :set_gift_record, only: [ :show, :edit, :update, :destroy ]
  before_action :ensure_owner, only: [ :edit, :update, :destroy ]
  before_action :ensure_accessible, only: [ :show ]

  def index
    # みんなのギフト画面：公開記録のみ表示
    base_query = GiftRecord.where(is_public: true)

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
    @total_amount = filtered_query.sum("gift_records.amount") || 0
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
            sorted_records = da_ids.filter_map { |id| records_hash[id] }

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

    # シェア確認用データの準備（ログインユーザーのみ）
    if user_signed_in? && params[:share_confirm] == "true" && params[:gift_record_id].present?
      gift_record_id = params[:gift_record_id].to_s
      dismissed_records = session[:dismissed_share_records] || []

      # 既に拒否されたギフト記録の場合はシェアモーダルを表示しない
      unless dismissed_records.include?(gift_record_id)
        @share_gift_record = current_user.gift_records
          .includes(:gift_person, :event, gift_person: :relationship)
          .find_by(id: params[:gift_record_id])
      end
    end

    # ページネーション用の安全なパラメータを準備
    @pagination_params = pagination_params

    # エラーハンドリング
    rescue ActiveRecord::RecordNotFound
      redirect_to root_path, alert: "記録が見つかりませんでした。"
    rescue StandardError => e
      Rails.logger.error "GiftRecords index error: #{e.message}"
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
    @total_amount = filtered_query.sum("gift_records.amount") || 0
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
    @gift_record = GiftRecord.new
    @gift_people = current_user.gift_people.where.not(name: [ nil, "" ])
    prepare_events_for_form
  end

  def create
    # 新しいギフト相手を作成する場合
    if params[:gift_record][:gift_people_id] == "new"
      # gift_personパラメータが存在しない場合
      unless params[:gift_person].present?
        # gift_recordは一時的なオブジェクトとして作成（バリデーションは実行しない）
        @gift_record = GiftRecord.new(gift_record_params.except(:gift_people_id))
        @gift_record.user = current_user
        @gift_people = current_user.gift_people.where.not(name: [ nil, "" ])
        prepare_events_for_form
        @gift_person = current_user.gift_people.build  # エラー表示用の空オブジェクト
        # ギフト相手のバリデーションのみ実行
        @gift_person.valid?
        render :new, status: :unprocessable_entity
        return
      end

      # ギフト相手を先に作成（gift_record_idなし）
      @gift_person = current_user.gift_people.build(gift_person_params)

      if @gift_person.save
        # ギフト記録を作成してギフト相手と関連付け
        @gift_record = current_user.gift_records.build(gift_record_params.except(:gift_people_id))
        @gift_record.gift_person = @gift_person

        if @gift_record.save
          flash_success(:created, item: GiftRecord.model_name.human)
          redirect_to gift_records_path(share_confirm: true, gift_record_id: @gift_record.id)
        else
          # ギフト記録の作成に失敗した場合、ギフト相手を削除
          @gift_person.destroy
          @gift_record = current_user.gift_records.build(gift_record_params.except(:gift_people_id))
          @gift_people = current_user.gift_people.where.not(name: [ nil, "" ])
          prepare_events_for_form

          flash.now[:alert] = "ギフト記録の作成に失敗しました"
          render :new, status: :unprocessable_entity
        end
      else
        # gift_recordは一時的なオブジェクトとして作成（バリデーションは実行しない）
        @gift_record = GiftRecord.new(gift_record_params.except(:gift_people_id))
        @gift_record.user = current_user
        @gift_people = current_user.gift_people.where.not(name: [ nil, "" ])
        prepare_events_for_form

        # ギフト相手のバリデーションエラーをフォームで表示
        render :new, status: :unprocessable_entity
      end
    else
      # 既存のギフト相手を選択する場合
      @gift_record = current_user.gift_records.build(gift_record_params)
      if @gift_record.save
        flash_success(:created, item: GiftRecord.model_name.human)
        redirect_to gift_records_path(share_confirm: true, gift_record_id: @gift_record.id)
      else
        # エラー時のフォーム再表示用データ準備
        @gift_people = current_user.gift_people.where.not(name: [ nil, "" ])
        prepare_events_for_form
        render :new, status: :unprocessable_entity
      end
    end
  end

  def show
    # セキュリティ: set_gift_recordとensure_accessibleで処理済み
    # コメントも事前読み込み済み（set_gift_recordで処理）
  end

  def edit
    # セキュリティ: set_gift_recordとensure_ownerで処理済み
    @gift_people = current_user.gift_people.where.not(name: [ nil, "" ])
    prepare_events_for_form
  end

  def update
    # デバッグ: 受信したパラメータをログ出力
    Rails.logger.debug "=== GiftRecord Update Debug ==="
    Rails.logger.debug "All params: #{params.inspect}"
    Rails.logger.debug "Gift record params: #{params[:gift_record].inspect}"
    Rails.logger.debug "Delete image IDs: #{params.dig(:gift_record, :delete_image_ids).inspect}"
    Rails.logger.debug "Current images count: #{@gift_record.images.count}"
    Rails.logger.debug "================================"

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

  def gift_record_params
    params.require(:gift_record).permit(
      :title, :description, :body,
      :gift_people_id, :memo, :item_name, :amount, :gift_at, :event_id, :is_public, :commentable,
      :gift_item_category_id, images: [], delete_image_ids: []
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
end
