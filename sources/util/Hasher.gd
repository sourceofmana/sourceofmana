extends RefCounted
class_name Hasher

#
const DefaultSaltSize : int				= 16

# Password
static func GenerateSalt(length : int = DefaultSaltSize) -> String:
	var rng : RandomNumberGenerator = RandomNumberGenerator.new()
	var salt : String = ""
	for i in length:
		# Printable ASCII characters
		salt += char(rng.randi_range(33, 126))
	return salt

static func HashPassword(password : String, salt : String) -> String:
	var hashContext : HashingContext = HashingContext.new()
	hashContext.start(HashingContext.HASH_SHA256)
	hashContext.update((salt + password).to_utf8_buffer())
	return hashContext.finish().hex_encode()
