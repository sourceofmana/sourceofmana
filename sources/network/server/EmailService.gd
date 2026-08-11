extends Node
class_name EmailService

#
const PasswordResetTemplatePath : String	= "conf/email_password_reset.html"
const SmtpApiUrl : String					= "https://api.brevo.com/v3/smtp/email"

var apiKey : String							= ""
var senderName : String						= ""
var senderEmail : String					= ""
var passwordResetTemplate : String			= ""
var httpRequest : HTTPRequest				= null

# Password reset storage: { accountID: { "code_hash": String, "created": int, "expires": int } }
var pendingResets : Dictionary			= {}

#
func _ready():
	apiKey = Conf.GetString("Email", "Email-ApiKey", Conf.Type.CREDENTIAL)
	senderName = Conf.GetString("Email", "Email-SenderName", Conf.Type.CREDENTIAL)
	senderEmail = Conf.GetString("Email", "Email-SenderAddress", Conf.Type.CREDENTIAL)
	if senderName.is_empty():
		senderName = "Source of Mana"
	passwordResetTemplate = FileSystem.LoadFile(PasswordResetTemplatePath)
	httpRequest = HTTPRequest.new()
	add_child(httpRequest)
	httpRequest.request_completed.connect(RequestCompleted)

	if IsConfigured():
		Util.PrintLog("EmailService", "Initialized with sender: %s" % senderEmail)
	elif apiKey.is_empty():
		Util.PrintLog("EmailService", "Not configured: missing API key")
	else:
		Util.PrintLog("EmailService", "Not configured: missing sender address")

#
func IsConfigured() -> bool:
	return not apiKey.is_empty() and not senderEmail.is_empty()

func SendPasswordResetEmail(toEmail : String, code : String) -> void:
	assert(IsConfigured(), "EmailService is not configured, can't send password reset email")


	var headers : PackedStringArray = [
		"api-key: %s" % apiKey,
		"Content-Type: application/json",
		"accept: application/json"
	]

	var body : Dictionary = {
		"sender": {
			"name": senderName,
			"email": senderEmail
		},
		"to": [
			{ "email": toEmail }
		],
		"subject": "Password Reset Request",
		"htmlContent": FormatPasswordResetEmail(code)
	}

	Util.PrintLog("EmailService", "Sending password reset email to: %s" % toEmail)
	var err : Error = httpRequest.request(SmtpApiUrl, headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		Util.PrintLog("EmailService", "Failed to initiate HTTP request (error: %d)" % err)

func FormatPasswordResetEmail(code : String) -> String:
	if passwordResetTemplate.is_empty():
		return "<p>Your password reset code is: <strong>%s</strong></p><p>This code expires in %d minutes.</p>" % [code, NetworkCommons.ResetCodeExpiryMinutes]
	return passwordResetTemplate.replace("{CODE}", code).replace("{EXPIRY_MINUTES}", str(NetworkCommons.ResetCodeExpiryMinutes)).replace("{SENDER_NAME}", senderName)

func RequestCompleted(result : int, responseCode : int, _headers : PackedStringArray, body : PackedByteArray):
	if result != HTTPRequest.RESULT_SUCCESS or responseCode < 200 or responseCode >= 300:
		var responseBody : String = body.get_string_from_utf8()
		Util.PrintLog("EmailService", "Failed to send email (result: %d, code: %d, body: %s)" % [result, responseCode, responseBody])
	else:
		Util.PrintLog("EmailService", "Email sent successfully (code: %d)" % responseCode)

# Password Reset Storage
func CreateReset(accountID : int, codeHash : String):
	var now : int = SQLCommons.Timestamp()
	pendingResets[accountID] = {
		"code_hash": codeHash,
		"created": now,
		"expires": now + NetworkCommons.ResetCodeExpiryMinutes * 60,
	}

func HasRecentReset(accountID : int) -> bool:
	if not pendingResets.has(accountID):
		return false
	var cooldownThreshold : int = SQLCommons.Timestamp() - NetworkCommons.ResetCodeCooldownMinutes * 60
	return pendingResets[accountID]["created"] > cooldownThreshold

func ValidateReset(accountID : int, codeHash : String) -> bool:
	if not pendingResets.has(accountID):
		return false
	var entry : Dictionary = pendingResets[accountID]
	return entry["code_hash"] == codeHash and entry["expires"] > SQLCommons.Timestamp()

func RemoveReset(accountID : int):
	pendingResets.erase(accountID)
