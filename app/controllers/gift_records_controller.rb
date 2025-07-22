class GiftRecordsController < ApplicationController
  before_action :authenticate_user!, except: [ :index, :show ]
  before_action :set_gift_record, only: [ :show, :edit, :update, :destroy ]
  before_action :ensure_owner, only: [ :edit, :update, :destroy ]
  before_action :ensure_accessible, only: [ :show ]

  def index
    # プライバシーを考慮したギフト記録の取得
    if user_signed_in?
      # ログインユーザー：公開記録 + 自分の記録（公開・非公開問わず）
      base_query = GiftRecord.where("gift_records.is_public = ? OR gift_records.user_id = ?", true, current_user.id)
    else
      # 未ログインユーザー：公開記録のみ
      base_query = GiftRecord.where(is_public: true)
    end

    # 関連テーブルの完全な事前読み込み
    @gift_records = base_query
      .includes(:gift_person, :event, :user, gift_person: :relationship)
      .order(created_at: :desc)

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

    if params[:date_from].present?
      @gift_records = @gift_records.where("gift_at >= ?", params[:date_from])
    end

    if params[:date_to].present?
      @gift_records = @gift_records.where("gift_at <= ?", params[:date_to])
    end

    # ページネーション（将来の実装のため）
    # @gift_records = @gift_records.page(params[:page]).per(20)

    # フィルタリング用のオプション準備（実際に使われているギフト相手のみ）
    @gift_people_options = base_query
      .joins(:gift_person)
      .select("gift_people.name, gift_people.id")
      .where.not("gift_people.name" => [ nil, "" ])
      .distinct
      .order("gift_people.name")
      .pluck("gift_people.name", "gift_people.id")

    # 統計情報（ダッシュボード要素）
    @total_records = @gift_records.count
    @total_amount = @gift_records.sum("gift_records.amount") || 0
    @current_month_records = base_query.where(
      "gift_records.gift_at" => Date.current.beginning_of_month..Date.current.end_of_month
    ).count

    # エラーハンドリング
    rescue ActiveRecord::RecordNotFound
      redirect_to root_path, alert: "記録が見つかりませんでした。"
    rescue StandardError => e
      Rails.logger.error "GiftRecords index error: #{e.message}"
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
        @gift_record = current_user.gift_records.build(gift_record_params.except(:gift_people_id))
        @gift_people = current_user.gift_people.where.not(name: [ nil, "" ])
        prepare_events_for_form
        @gift_person = current_user.gift_people.build  # エラー表示用の空オブジェクト
        @gift_person.errors.add(:name, "を入力してください")
        flash.now[:alert] = "ギフト相手の情報を入力してください。"
        render :new, status: :unprocessable_entity
        return
      end
      # 名前が空でないかチェック
      if params[:gift_person][:name].blank?
        @gift_record = current_user.gift_records.build(gift_record_params.except(:gift_people_id))
        @gift_people = current_user.gift_people.where.not(name: [ nil, "" ])
        prepare_events_for_form
        @gift_person = current_user.gift_people.build(gift_person_params)  # エラー表示用
        @gift_person.errors.add(:name, "を入力してください")
        flash.now[:alert] = "ギフト相手の名前を入力してください。"
        render :new, status: :unprocessable_entity
        return
      end

      # ギフト相手を先に作成（gift_record_idなし）
      @gift_person = current_user.gift_people.build(gift_person_params)

      if @gift_person.save
        # ギフト記録を作成してギフト相手と関連付け
        @gift_record = current_user.gift_records.build(gift_record_params.except(:gift_people_id))
        @gift_record.gift_people = @gift_person

        if @gift_record.save
          # ギフト相手にgift_record_idを設定
          @gift_person.update(gift_record_id: @gift_record.id)
          flash_success(:created, item: GiftRecord.model_name.human)
          redirect_to gift_records_path
          return
        else
          # ギフト記録の作成に失敗した場合、ギフト相手を削除
          @gift_person.destroy
          @gift_record = current_user.gift_records.build(gift_record_params.except(:gift_people_id))
          @gift_people = current_user.gift_people.where.not(name: [ nil, "" ])
          prepare_events_for_form

          flash.now[:alert] = "ギフト記録の作成に失敗しました"
          render :new, status: :unprocessable_entity
          return
        end
      else
        @gift_record = current_user.gift_records.build(gift_record_params.except(:gift_people_id))
        @gift_people = current_user.gift_people.where.not(name: [ nil, "" ])
        prepare_events_for_form

        # ギフト相手のエラーメッセージをflashに追加
        error_messages = @gift_person.errors.full_messages.join(", ")
        flash.now[:alert] = "ギフト相手の作成に失敗しました: #{error_messages}"
        render :new, status: :unprocessable_entity
        return
      end
    else
      @gift_record = current_user.gift_records.build(gift_record_params)
      if @gift_record.save
        flash_success(:created, item: GiftRecord.model_name.human)
        redirect_to gift_records_path
        return
      end
    end

    @gift_record ||= current_user.gift_records.build
    @gift_people = current_user.gift_people.where.not(name: [ nil, "" ])
    prepare_events_for_form
    flash.now[:alert] = t("defaults.flash_message.not_created", item: GiftRecord.model_name.human)
    render :new, status: :unprocessable_entity
  end

  def show
    # セキュリティ: set_gift_recordとensure_ownerで処理済み
    # コメント機能は将来実装予定
  end

  def edit
    # セキュリティ: set_gift_recordとensure_ownerで処理済み
    @gift_people = current_user.gift_people.where.not(name: [ nil, "" ])
    prepare_events_for_form
  end

  def update
    if @gift_record.update(gift_record_params)
      flash_success(:updated, item: GiftRecord.model_name.human)
      redirect_to @gift_record
    else
      @gift_people = current_user.gift_people.where.not(name: [ nil, "" ])
      prepare_events_for_form
      flash.now[:alert] = t("defaults.flash_message.not_updated", item: GiftRecord.model_name.human)
      render :edit, status: :unprocessable_entity
    end
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

  private

  def gift_record_params
    params.require(:gift_record).permit(:title, :description, :body, :gift_record_image, :gift_record_image_cache, :gift_people_id, :memo, :item_name, :amount, :gift_at, :event_id, :is_public)
  end

  def gift_person_params
    params.require(:gift_person).permit(:name, :relationship_id, :birthday, :likes, :dislikes, :memo)
  end

  # セキュリティ: ギフト記録を取得
  def set_gift_record
    if action_name == "show"
      # show アクション：公開記録または自分の記録
      if user_signed_in?
        @gift_record = GiftRecord.where("gift_records.is_public = ? OR gift_records.user_id = ?", true, current_user.id)
          .includes(:gift_people, :event, :user, gift_people: :relationship)
          .find(params[:id])
      else
        @gift_record = GiftRecord.where("gift_records.is_public = ?", true)
          .includes(:gift_people, :event, :user, gift_people: :relationship)
          .find(params[:id])
      end
    else
      # edit, update, destroy アクション：自分の記録のみ
      @gift_record = current_user.gift_records
        .includes(:gift_people, :event, gift_people: :relationship)
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

  # イベント選択肢の準備
  def prepare_events_for_form
    @events = Event.all.order(:name)
    @popular_events = Event.joins(:gift_records)
      .group("events.id")
      .order("COUNT(gift_records.id) DESC")
      .limit(5)
  end
end
