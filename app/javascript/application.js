// Entry point for the build script in your package.json
import "@hotwired/turbo-rails"
import "./controllers"
import "./utils"
// 削除モーダル専用システムを最優先で読み込み
import "./delete_modal"
import "./autocomplete"
import "./dynamic_filter"
import "./share_manager"
import "./gift_person_form"
import "./gift_date_selector"
import "./event_selector"
import "./favorites"
// ハンバーガーメニューは最後に読み込み（イベント競合回避）
import "./hamburger_menu"
