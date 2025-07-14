class GiftRecordsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_gift_record, only: [:show, :edit, :update, :destroy]
  before_action :ensure_owner, only: [:show, :edit, :update, :destroy]

  def index
    # ベテランバックエンドエンジニアによる高パフォーマンス実装
    
    # セキュリティ: ユーザー固有のデータのみ取得
    base_query = current_user.gift_records
    
    # N+1問題回避: 関連テーブルを事前読み込み
    @gift_records = base_query
      .includes(:gift_people, :event, gift_people: :relationship)
      .order(created_at: :desc)
    
    # 検索機能（オプション）
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      @gift_records = @gift_records.joins(:gift_people)
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
    
    # フィルタリング用のオプション準備
    @gift_people_options = current_user.gift_people
      .where.not(name: [nil, ''])
      .order(:name)
      .pluck(:name, :id)
    
    # 統計情報（ダッシュボード要素）
    @total_records = @gift_records.count
    @total_amount = @gift_records.sum(:amount) || 0
    @current_month_records = base_query.where(
      gift_at: Date.current.beginning_of_month..Date.current.end_of_month
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
    @gift_people = current_user.gift_people.where.not(name: [nil, ''])
    prepare_events_for_form
    prepare_relationships_for_form
  end

  def create
    # 新しいギフト相手を作成する場合
    if params[:gift_record][:gift_people_id] == "new"
      # gift_personパラメータが存在しない場合
      unless params[:gift_person].present?
        @gift_record = current_user.gift_records.build(gift_record_params.except(:gift_people_id))
        @gift_people = current_user.gift_people.where.not(name: [nil, ''])
        prepare_events_for_form
        prepare_relationships_for_form
        @gift_person = current_user.gift_people.build  # エラー表示用の空オブジェクト
        @gift_person.errors.add(:name, "を入力してください")
        flash.now[:danger] = "ギフト相手の情報を入力してください。"
        render :new, status: :unprocessable_entity
        return
      end
      # 名前が空でないかチェック
      if params[:gift_person][:name].blank?
        @gift_record = current_user.gift_records.build(gift_record_params.except(:gift_people_id))
        @gift_people = current_user.gift_people.where.not(name: [nil, ''])
        prepare_events_for_form
        prepare_relationships_for_form
        @gift_person = current_user.gift_people.build(gift_person_params)  # エラー表示用
        @gift_person.errors.add(:name, "を入力してください")
        flash.now[:danger] = "ギフト相手の名前を入力してください。"
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
          redirect_to gift_records_path, success: t("defaults.flash_message.created", item: GiftRecord.model_name.human)
          return
        else
          # ギフト記録の作成に失敗した場合、ギフト相手を削除
          @gift_person.destroy
          @gift_record = current_user.gift_records.build(gift_record_params.except(:gift_people_id))
          @gift_people = current_user.gift_people.where.not(name: [nil, ''])
          prepare_events_for_form
          prepare_relationships_for_form
          
          flash.now[:danger] = "ギフト記録の作成に失敗しました"
          render :new, status: :unprocessable_entity
          return
        end
      else
        @gift_record = current_user.gift_records.build(gift_record_params.except(:gift_people_id))
        @gift_people = current_user.gift_people.where.not(name: [nil, ''])
        prepare_events_for_form
        prepare_relationships_for_form
        
        # ギフト相手のエラーメッセージをflashに追加
        error_messages = @gift_person.errors.full_messages.join(", ")
        flash.now[:danger] = "ギフト相手の作成に失敗しました: #{error_messages}"
        render :new, status: :unprocessable_entity
        return
      end
    else
      @gift_record = current_user.gift_records.build(gift_record_params)
      if @gift_record.save
        redirect_to gift_records_path, success: t("defaults.flash_message.created", item: GiftRecord.model_name.human)
        return
      end
    end
    
    @gift_record ||= current_user.gift_records.build
    @gift_people = current_user.gift_people.where.not(name: [nil, ''])
    prepare_events_for_form
    prepare_relationships_for_form
    flash.now[:danger] = t("defaults.flash_message.not_created", item: GiftRecord.model_name.human)
    render :new, status: :unprocessable_entity
  end

  def show
    # セキュリティ: set_gift_recordとensure_ownerで処理済み
    # コメント機能は将来実装予定
  end

  def edit
    # セキュリティ: set_gift_recordとensure_ownerで処理済み
    @gift_people = current_user.gift_people.where.not(name: [nil, ''])
    prepare_events_for_form
    prepare_relationships_for_form
  end

  def update
    if @gift_record.update(gift_record_params)
      redirect_to @gift_record, 
        success: t("defaults.flash_message.updated", item: GiftRecord.model_name.human)
    else
      @gift_people = current_user.gift_people.where.not(name: [nil, ''])
      prepare_events_for_form
      prepare_relationships_for_form
      flash.now[:danger] = t("defaults.flash_message.not_updated", item: GiftRecord.model_name.human)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    item_name = @gift_record.item_name.presence || "ギフト記録"
    
    if @gift_record.destroy
      redirect_to gift_records_path, 
        success: "#{item_name}を削除しました。"
    else
      redirect_to gift_records_path, 
        alert: "削除に失敗しました。再度お試しください。"
    end
  rescue StandardError => e
    Rails.logger.error "GiftRecord deletion error: #{e.message}"
    redirect_to gift_records_path, 
      alert: "削除中にエラーが発生しました。"
  end

  private

  def gift_record_params
    params.require(:gift_record).permit(:title, :description, :body, :gift_record_image, :gift_record_image_cache, :gift_people_id, :memo, :item_name, :amount, :gift_at, :event_id)
  end

  def gift_person_params
    params.require(:gift_person).permit(:name, :relationship_id, :birthday, :likes, :dislikes, :memo)
  end

  # セキュリティ: ギフト記録を取得（ユーザー固有のデータのみ）
  def set_gift_record
    @gift_record = current_user.gift_records
      .includes(:gift_people, :event, gift_people: :relationship)
      .find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to gift_records_path, alert: "指定されたギフト記録が見つかりません。"
  end

  # セキュリティ: 所有者確認
  def ensure_owner
    unless @gift_record&.user == current_user
      redirect_to gift_records_path, alert: "アクセス権限がありません。"
    end
  end

  # イベントデータの準備（既存データを使用）
  def prepare_events_for_form
    # 既存のEventテーブルからデータを取得
    @events = Event.all.order(:name)
    @popular_events = @events.limit(5)
    
    Rails.logger.info "Events loaded from database: #{@events.count} events"
    Rails.logger.info "Event names: #{@events.pluck(:name).join(', ')}" if @events.any?
    
  rescue StandardError => e
    Rails.logger.error "Error loading events: #{e.message}"
    @events = []
    @popular_events = []
  end

  # 関係性データの準備
  def prepare_relationships_for_form
    Rails.logger.info "=== prepare_relationships_for_form START ==="
    
    # デバッグ情報を出力
    Relationship.debug_relationships_info
    
    # デフォルト関係性が存在しない場合は作成
    relationships_count = Relationship.default_relationships
    Rails.logger.info "Default relationships creation result: #{relationships_count} relationships"
    
    # 関係性データを取得
    @relationships = Relationship.active.ordered
    
    Rails.logger.info "Relationships prepared for form: #{@relationships.count} relationships loaded"
    Rails.logger.info "Relationship names: #{@relationships.pluck(:name).join(', ')}" if @relationships.any?
    
    # 関係性が0件の場合はエラーレベルでログ出力とリトライ
    if @relationships.empty?
      Rails.logger.error "No relationships found in database! Performing emergency creation..."
      
      # 強制的に最低限の関係性を作成
      emergency_relationships = ['父', '母', 'その他']
      emergency_relationships.each do |name|
        Relationship.create!(name: name) unless Relationship.exists?(name: name)
      end
      
      @relationships = Relationship.active.ordered
      Rails.logger.info "Emergency relationships created: #{@relationships.count} relationships now available"
    end
    
    Rails.logger.info "=== prepare_relationships_for_form END ==="
    
  rescue StandardError => e
    Rails.logger.error "CRITICAL ERROR in prepare_relationships_for_form: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    
    # フォールバック: 空の配列を設定
    @relationships = []
    
    Rails.logger.error "Using fallback relationships due to critical error"
  end
end
