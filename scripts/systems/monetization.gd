extends Node

## Real-money purchases and rewarded ads, behind one small API so the rest of
## the game never talks to a store SDK directly.
##
##   Monetization.buy(offer_id)            -> purchase_finished(offer_id, ok, message)
##   Monetization.show_rewarded(offer_id)  -> rewarded_finished(offer_id, ok, message)
##   Monetization.price_text(offer_id)     -> the store's localized price, or the catalogue's
##
## What each offer gives lives in GameState (COIN_OFFERS / ENERGY_OFFERS); this
## node only moves the money/ad part and then asks GameState to grant.
##
## Backends, picked once in _ready:
##   PLAY       Android with both plugins installed and enabled:
##              - godot-google-play-billing (class BillingClient)
##              - poing-godot-admob (classes MobileAds, RewardedAdLoader…)
##              Each half is independent: with only one plugin present, the
##              other half reports "not available".
##   SIMULATED  debug builds without the plugins (editor, desktop, debug APK):
##              every purchase and ad succeeds after a short delay, so the
##              whole flow can be exercised. Never active in release builds.
##   NONE       release build without plugins: everything reports unavailable.
##
## The plugin classes are looked up by name at runtime (never referenced
## directly), so the project still compiles while the plugins are absent.
##
## Installed versions this was written against: GodotGooglePlayBilling 3.3.0
## and poing-godot-admob 5.1.0 (AdMob app id: Project Settings > admob/
## general/android/app_id).
##
## NOTE: the PLAY paths follow those plugins' source but have not been run on
## a device yet — test them with a Play Console test track before release.

signal purchase_finished(offer_id: String, success: bool, message: String)
signal rewarded_finished(offer_id: String, success: bool, message: String)
## Store prices arrived (or changed): screens showing price_text should refresh.
signal prices_updated

enum Backend { NONE, SIMULATED, PLAY }

## Google's public test unit for rewarded ads. Replace with the real unit id
## from the AdMob console before release (test ads never pay out).
const REWARDED_TEST_UNIT := "ca-app-pub-3940256099942544/5224354917"
const REWARDED_UNIT := REWARDED_TEST_UNIT

## Google Play Billing constants (stable values of the Billing Library).
const RESPONSE_OK := 0
const RESPONSE_USER_CANCELED := 1
const PURCHASE_STATE_PURCHASED := 1
const PURCHASE_STATE_PENDING := 2

const SIMULATED_DELAY := 0.6

var billing_backend: int = Backend.NONE
var ads_backend: int = Backend.NONE

var _billing: Object
var _billing_script: Script
var _prices := {}
## Offer the player is currently trying to buy / watching an ad for.
var _buying := ""
var _watching := ""
var _rewarded_ad: Object
var _reward_earned := false
## purchase_token -> offer_id for purchases granted and waiting to be consumed.
var _consuming := {}

func _ready() -> void:
	var on_android := OS.get_name() == "Android"
	_billing_script = _global_class("BillingClient")
	if on_android and _billing_script != null:
		billing_backend = Backend.PLAY
		_start_billing()
	elif OS.is_debug_build():
		billing_backend = Backend.SIMULATED
	if on_android and _global_class("MobileAds") != null and _global_class("RewardedAdLoader") != null:
		ads_backend = Backend.PLAY
		_request_ad_consent()
	elif OS.is_debug_build():
		ads_backend = Backend.SIMULATED

## A script registered with `class_name` anywhere in the project (plugins
## included), or null when it doesn't exist.
func _global_class(type_name: String) -> Script:
	for entry in ProjectSettings.get_global_class_list():
		if str(entry.get("class", "")) == type_name:
			return load(str(entry.get("path", ""))) as Script
	return null

# --- Public API -------------------------------------------------------------------

func can_buy() -> bool:
	return billing_backend != Backend.NONE

func can_show_rewarded() -> bool:
	return ads_backend != Backend.NONE

func is_busy() -> bool:
	return _buying != "" or _watching != ""

## The store's own localized price when known, else "USD <catalogue price>".
func price_text(offer_id: String) -> String:
	if _prices.has(offer_id):
		return str(_prices[offer_id])
	var found := GameState.find_store_offer(offer_id)
	return "USD %s" % str(found.get("offer", {}).get("usd", "?")) if not found.is_empty() else ""

func buy(offer_id: String) -> void:
	if is_busy():
		return
	if GameState.find_store_offer(offer_id).is_empty():
		purchase_finished.emit(offer_id, false, "Oferta desconocida.")
		return
	match billing_backend:
		Backend.SIMULATED:
			_buying = offer_id
			await get_tree().create_timer(SIMULATED_DELAY).timeout
			_finish_purchase(offer_id, GameState.grant_store_offer(offer_id, "sim-%d" % Time.get_ticks_usec()), "[simulada] Compra completada.")
		Backend.PLAY:
			if not _billing.is_ready():
				_billing.start_connection()
				purchase_finished.emit(offer_id, false, "Sin conexión con la tienda. Prueba de nuevo.")
				return
			_buying = offer_id
			var result: Dictionary = _billing.purchase(offer_id)
			if int(result.get("response_code", -1)) != RESPONSE_OK:
				_finish_purchase(offer_id, false, "No se pudo abrir la compra.")
		_:
			purchase_finished.emit(offer_id, false, "La tienda no está disponible.")

## Shows a rewarded ad; the offer is granted only if the ad was watched through.
func show_rewarded(offer_id: String) -> void:
	if is_busy():
		return
	match ads_backend:
		Backend.SIMULATED:
			_watching = offer_id
			await get_tree().create_timer(SIMULATED_DELAY).timeout
			_finish_rewarded(GameState.grant_ad_offer(offer_id), "[simulado] Anuncio visto.")
		Backend.PLAY:
			if _rewarded_ad == null:
				_load_rewarded()
				rewarded_finished.emit(offer_id, false, "El anuncio todavía no está listo. Prueba en unos segundos.")
				return
			_watching = offer_id
			_reward_earned = false
			var listener: Object = _global_class("OnUserEarnedRewardListener").new()
			listener.on_user_earned_reward = func(_item): _reward_earned = true
			_rewarded_ad.show(listener)
		_:
			rewarded_finished.emit(offer_id, false, "Los anuncios no están disponibles.")

func _finish_purchase(offer_id: String, success: bool, message: String) -> void:
	_buying = ""
	purchase_finished.emit(offer_id, success, message)

func _finish_rewarded(success: bool, message: String) -> void:
	var offer_id := _watching
	_watching = ""
	rewarded_finished.emit(offer_id, success, message)

# --- Google Play Billing ------------------------------------------------------------

func _start_billing() -> void:
	_billing = _billing_script.new()
	_billing.connected.connect(_on_billing_connected)
	_billing.disconnected.connect(func(): pass)
	_billing.connect_error.connect(func(code, message): push_warning("Billing: connect error %s %s" % [code, message]))
	_billing.query_product_details_response.connect(_on_product_details)
	_billing.query_purchases_response.connect(_on_purchases)
	_billing.on_purchase_updated.connect(_on_purchases)
	_billing.consume_purchase_response.connect(_on_consumed)
	_billing.start_connection()

func _product_type_inapp() -> int:
	var types = _billing_script.get_script_constant_map().get("ProductType", {})
	return int(types.get("INAPP", 0)) if types is Dictionary else 0

func _on_billing_connected() -> void:
	_billing.query_product_details(PackedStringArray(GameState.store_offer_ids()), _product_type_inapp())
	# Purchases paid for but not delivered yet (app closed mid-purchase, a
	# pending payment that cleared later…) are delivered now.
	_billing.query_purchases(_product_type_inapp())

func _on_product_details(response: Dictionary) -> void:
	if int(response.get("response_code", -1)) != RESPONSE_OK:
		return
	for details in response.get("product_details", []):
		if not details is Dictionary:
			continue
		var price := _find_key(details, "formatted_price")
		var id := str(details.get("id", details.get("product_id", "")))
		if id != "" and price != "":
			_prices[id] = price
	prices_updated.emit()

## First string stored under `key` anywhere inside a nested dictionary/array
## (the product-details layout differs between one-time products and offers).
func _find_key(data: Variant, key: String) -> String:
	if data is Dictionary:
		if data.has(key):
			return str(data[key])
		for value in data.values():
			var found := _find_key(value, key)
			if found != "":
				return found
	elif data is Array:
		for value in data:
			var found := _find_key(value, key)
			if found != "":
				return found
	return ""

## Purchase updates (after the Play sheet closes) and the purchase query on
## connect both land here.
func _on_purchases(response: Dictionary) -> void:
	var code := int(response.get("response_code", -1))
	if code != RESPONSE_OK:
		if _buying != "":
			_finish_purchase(_buying, false, "Compra cancelada." if code == RESPONSE_USER_CANCELED else "La compra no se completó.")
		return
	for purchase in response.get("purchases", []):
		if not purchase is Dictionary:
			continue
		var state := int(purchase.get("purchase_state", 0))
		var token := str(purchase.get("purchase_token", ""))
		for product_id in purchase.get("product_ids", []):
			var offer_id := str(product_id)
			if state == PURCHASE_STATE_PENDING:
				if _buying == offer_id:
					_finish_purchase(offer_id, false, "Pago pendiente: se entregará cuando se confirme.")
				continue
			if state != PURCHASE_STATE_PURCHASED or token == "":
				continue
			# Grant first (idempotent per token), then consume so the product
			# can be bought again. A crash in between re-delivers nothing.
			GameState.grant_store_offer(offer_id, token)
			_consuming[token] = offer_id
			_billing.consume_purchase(token)

func _on_consumed(response: Dictionary) -> void:
	var token := str(response.get("token", ""))
	var offer_id := str(_consuming.get(token, ""))
	_consuming.erase(token)
	if offer_id != "" and offer_id == _buying:
		_finish_purchase(offer_id, true, "¡Compra completada!")

# --- AdMob rewarded ads ---------------------------------------------------------------

## Privacy consent first (Google's UMP: required in the EEA/UK, a no-op
## elsewhere), then the ads SDK starts whatever the answer was — UMP itself
## makes the SDK serve only what the player allowed.
func _request_ad_consent() -> void:
	var ump: Script = _global_class("UserMessagingPlatform")
	var params_class: Script = _global_class("ConsentRequestParameters")
	if ump == null or params_class == null:
		_start_ads()
		return
	var info: Object = ump.get("consent_information")
	info.update(params_class.new(), func():
		if info.get_is_consent_form_available():
			ump.load_consent_form(func(form): form.show(func(_error): _start_ads()), func(_error): _start_ads())
		else:
			_start_ads()
	, func(_error): _start_ads())

## UMP's PrivacyOptionsRequirementStatus.REQUIRED: Google requires the app
## to offer a way to reopen the ad-privacy choices (EEA/UK and similar).
const PRIVACY_OPTIONS_REQUIRED := 2

## Whether Configuración must show the "Privacidad de anuncios" entry.
func ad_privacy_options_required() -> bool:
	if ads_backend != Backend.PLAY:
		return false
	var ump: Script = _global_class("UserMessagingPlatform")
	if ump == null:
		return false
	return int(ump.get("consent_information").get_privacy_options_requirement_status()) == PRIVACY_OPTIONS_REQUIRED

## Reopens Google's form so the player can change their ad-privacy choice.
func show_ad_privacy_options() -> void:
	var ump: Script = _global_class("UserMessagingPlatform")
	if ump != null:
		ump.show_privacy_options_form(func(_error): pass)

var _ads_started := false
var _ads_initialized := false

func _start_ads() -> void:
	if _ads_started:
		return
	_ads_started = true
	var mobile_ads: Script = _global_class("MobileAds")
	var listener_script: Script = _global_class("OnInitializationCompleteListener")
	if mobile_ads == null or listener_script == null:
		push_warning("AdMob: falta la clase para confirmar la inicialización; anuncios desactivados.")
		return
	var listener: Object = listener_script.new()
	listener.on_initialization_complete = func(_status):
		_ads_initialized = true
		_load_rewarded()
	mobile_ads.call("initialize", listener)

func _load_rewarded() -> void:
	if not _ads_initialized:
		return
	var callback: Object = _global_class("RewardedAdLoadCallback").new()
	callback.on_ad_failed_to_load = func(_error): _rewarded_ad = null
	callback.on_ad_loaded = func(ad):
		_rewarded_ad = ad
		var content: Object = _global_class("FullScreenContentCallback").new()
		content.on_ad_dismissed_full_screen_content = _on_rewarded_closed
		content.on_ad_failed_to_show_full_screen_content = func(_error): _on_rewarded_closed()
		ad.full_screen_content_callback = content
	_global_class("RewardedAdLoader").new().load(REWARDED_UNIT, _global_class("AdRequest").new(), callback)

func _on_rewarded_closed() -> void:
	if _rewarded_ad != null:
		_rewarded_ad.destroy()
		_rewarded_ad = null
	_load_rewarded()
	if _watching == "":
		return
	if _reward_earned:
		_finish_rewarded(GameState.grant_ad_offer(_watching), "¡Recompensa recibida!")
	else:
		_finish_rewarded(false, "Hay que ver el anuncio completo para recibir la recompensa.")
