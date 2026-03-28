extends ScrollContainer

#
@onready var currentPasswordField : LineEdit		= $AccountVBox/CurrentPassword/Text
@onready var newPasswordField : LineEdit			= $AccountVBox/NewPassword/Text
@onready var confirmPasswordField : LineEdit		= $AccountVBox/ConfirmPassword/Text
@onready var passwordStatusLabel : RichTextLabel	= $AccountVBox/StatusLabel

#
func OnPasswordChangeResult(err : NetworkCommons.AuthError):
	match err:
		NetworkCommons.AuthError.ERR_PASSWORD_CHANGE_OK:
			SetPasswordStatus("Password changed successfully.", false)
			currentPasswordField.clear()
			newPasswordField.clear()
			confirmPasswordField.clear()
		NetworkCommons.AuthError.ERR_PASSWORD_CHANGE_WRONG:
			SetPasswordStatus("Current password is incorrect.", true)

func SetPasswordStatus(text : String, isWarn : bool):
	var textColor : Color = UICommons.WarnTextColor if isWarn else UICommons.TextColor
	passwordStatusLabel.set_text("[color=#%s]%s[/color]" % [textColor.to_html(false), text])

#
func _on_change_button_pressed():
	var currentPassword : String = currentPasswordField.get_text()
	var newPassword : String = newPasswordField.get_text()
	var confirmPassword : String = confirmPasswordField.get_text()

	var currentErr : NetworkCommons.AuthError = NetworkCommons.CheckPasswordInformation(currentPassword)
	if currentErr != NetworkCommons.AuthError.ERR_OK:
		SetPasswordStatus("Current password is invalid.", true)
		currentPasswordField.grab_focus()
		return

	var newErr : NetworkCommons.AuthError = NetworkCommons.CheckPasswordInformation(newPassword)
	if newErr == NetworkCommons.AuthError.ERR_PASSWORD_SIZE:
		SetPasswordStatus("New password length should be between %d and %d characters." % [NetworkCommons.PasswordMinSize, NetworkCommons.PasswordMaxSize], true)
		newPasswordField.grab_focus()
		return
	elif newErr == NetworkCommons.AuthError.ERR_PASSWORD_VALID:
		SetPasswordStatus("New password should only include alpha-numeric characters and symbols.", true)
		newPasswordField.grab_focus()
		return

	if newPassword != confirmPassword:
		SetPasswordStatus("New passwords do not match.", true)
		confirmPasswordField.grab_focus()
		return

	Network.ChangePassword(currentPassword, newPassword)
