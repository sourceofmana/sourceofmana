extends RefCounted
class_name Hasher

#
const DefaultSaltSize : int				= 16
const DefaultTokenSize : int			= 32
const DefaultResetCodeLength : int		= 6

# Password
static func GenerateSalt(length : int = DefaultSaltSize) -> String:
	var rng : RandomNumberGenerator = RandomNumberGenerator.new()
	var salt : String = ""
	for i in length:
		salt += char(rng.randi_range(33, 126))
	return salt

static func HashPassword(password : String, salt : String = "") -> String:
	var hashContext : HashingContext = HashingContext.new()
	hashContext.start(HashingContext.HASH_SHA256)
	hashContext.update((salt + password).to_utf8_buffer())
	return hashContext.finish().hex_encode()

# Reset Code
static func GenerateResetCode(length : int = DefaultResetCodeLength) -> String:
	var rng : RandomNumberGenerator = RandomNumberGenerator.new()
	var code : String = ""
	for i in length:
		code += str(rng.randi_range(0, 9))
	return code
