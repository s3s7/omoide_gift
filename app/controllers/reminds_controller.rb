class RemindsController < ApplicationController
  PAST_REMIND_LIMIT = 10
  before_action :authenticate_user!
  before_action :set_remind, only: [ :show, :edit, :update, :destroy, :resend ]
  before_action :ensure_owner, only: [ :show, :edit, :update, :destroy, :resend ]

  def index
    @reminds = current_user.reminds
                          .includes(gift_person: :relationship)
                          .order(:notification_at)

    # 今後の予定とイベント履歴を分離
    @upcoming_reminds = @reminds.unsent.where("notification_at >= ?", Date.current)
    @past_reminds = @reminds.sent.order(notification_sent_at: :desc).limit(PAST_REMIND_LIMIT)

    # 統計情報
    @total_reminds = @reminds.count
    @sent_count = @reminds.sent.count
    @upcoming_count = @upcoming_reminds.count
  end

  def show
  end

  def new
    @remind = current_user.reminds.build
    @gift_people = current_user.gift_people.includes(:relationship).order(:name)

    if @gift_people.empty?
      redirect_to gift_people_path, alert: "記念日を設定するにはまずギフト相手を登録してください。"
    end
  end

  def create
    @remind = current_user.reminds.build(basic_remind_params)

    # 通知日時を設定
    days_before = params[:remind][:notification_days_before]
    time_str = params[:remind][:notification_time]

    if days_before.present? && time_str.present?
      @remind.set_notification_sent_at(days_before, time_str)
    else
      @remind.errors.add(:base, "通知日数と通知時刻を設定してください")
    end

    if @remind.save
      redirect_to reminds_path, notice: "#{@remind.gift_person.name}さんの記念日リマインダーを作成しました。"
    else
      @gift_people = current_user.gift_people.includes(:relationship).order(:name)
      render :new, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to reminds_path, alert: "指定されたギフト相手が見つかりません。"
  end

  def edit
    @gift_people = current_user.gift_people.includes(:relationship).order(:name)
    # 現在の設定をビュー用に処理
    @current_notification_days_before = @remind.notification_days_before
    @current_notification_time = @remind.notification_time
  end

  def update
    # 基本パラメーターを更新
    @remind.assign_attributes(basic_remind_params)

    # 通知日時を再設定
    days_before = params[:remind][:notification_days_before]
    time_str = params[:remind][:notification_time]

    if days_before.present? && time_str.present?
      @remind.set_notification_sent_at(days_before, time_str)
    else
      @remind.errors.add(:base, "通知日数と通知時刻を設定してください")
    end

    if @remind.save
      # 編集時は通知状態をリセット
      @remind.update!(is_sent: false)

      redirect_to reminds_path, notice: "#{@remind.gift_person.name}さんの記念日リマインダーを更新しました。"
    else
      @gift_people = current_user.gift_people.includes(:relationship).order(:name)
      @current_notification_days_before = @remind.notification_days_before
      @current_notification_time = @remind.notification_time
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    person_name = @remind.gift_person.name
    @remind.destroy
    redirect_to reminds_path, notice: "#{person_name}さんの記念日リマインダーを削除しました。"
  end

  # 通知をリセットして再送可能にする
  def resend
    @remind.update!(is_sent: false)
    @remind.save!
    redirect_to reminds_path, notice: "#{@remind.gift_person.name}さんの通知をリセットしました。次回の定期実行時に再送されます。"
  rescue StandardError => e
    Rails.logger.error "Remind resend error: #{e.message}"
    redirect_to reminds_path, alert: "通知のリセットに失敗しました。"
  end

  private

  def set_remind
    @remind = current_user.reminds.includes(gift_person: :relationship).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to reminds_path, alert: "指定された記念日リマインダーが見つかりません。"
  end

  def ensure_owner
    unless @remind&.user == current_user
      redirect_to reminds_path, alert: "アクセス権限がありません。"
    end
  end

  def remind_params
    params.require(:remind).permit(:gift_person_id, :notification_at, :notification_sent_at, :notification_days_before, :notification_time)
  end

  def basic_remind_params
    params.require(:remind).permit(:gift_person_id, :notification_at)
  end
end
