require "CryptoSupport/handlers/rsa_complex_bypass_handler.h";
require "openssl/evp.h";
require "CryptoSupport/CryptoUtils.chpl";
require "CryptoSupport/primitives/asymmetricPrimitives.chpl";

module rsaKeySupport {

  use CryptoUtils;
  use CryptoUtils;
  use asymmetricPrimitives;
  use asymmetricPrimitives;

  proc generateKeys(bits: int) {
   var localKeyPair: asymmetricPrimitives.EVP_PKEY_PTR;
   var keyCtx = asymmetricPrimitives.EVP_PKEY_CTX_new_id(6: c_int, c_nil: asymmetricPrimitives.ENGINE_PTR);

   asymmetricPrimitives.EVP_PKEY_keygen_init(keyCtx);
   asymmetricPrimitives.EVP_PKEY_CTX_set_rsa_keygen_bits(keyCtx, bits: c_int);
   asymmetricPrimitives.EVP_PKEY_keygen(keyCtx, localKeyPair);
   return localKeyPair;
  }
}
