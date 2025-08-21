# 管理者用イベント管理コントローラー
class Admin::EventsController < Admin::BaseController
  before_action :set_event, only: [:edit, :update, :destroy]

  def index
    @events = Event.order(:name).page(params[:page]).per(per_page)
    log_admin_action("イベント一覧表示")
  end

  def new
    @event = Event.new
  end

  def create
    @event = Event.new(event_params)
    if @event.save
      admin_flash_success("イベントを作成しました。")
      log_admin_action("イベント作成", "Event", @event.id)
      redirect_to admin_events_path
    else
      admin_flash_error("イベントの作成に失敗しました。")
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    log_admin_action("イベント編集画面表示", "Event", @event.id)
  end

  def update
    if @event.update(event_params)
      admin_flash_success("イベントを更新しました。")
      log_admin_action("イベント更新", "Event", @event.id)
      redirect_to admin_events_path
    else
      admin_flash_error("イベントの更新に失敗しました。")
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @event.gift_records.exists?
      admin_flash_error("このイベントを使用しているギフト記録があるため削除できません。")
    elsif @event.destroy
      admin_flash_success("イベントを削除しました。")
      log_admin_action("イベント削除", "Event", @event.id, @event.name)
    else
      admin_flash_error("イベントの削除に失敗しました。")
    end
    redirect_to admin_events_path
  end

  private

  def set_event
    @event = Event.find(params[:id])
  end

  def event_params
    params.require(:event).permit(:name)
  end
end