require "openssl/evp.h", "-lcrypto";
require "openssl/aes.h", "openssl/rand.h";

require "CryptoSupport/hashSupport.chpl";
require "CryptoSupport/aesSupport.chpl";
require "CryptoSupport/kdfSupport.chpl";
require "CryptoSupport/CryptoUtils.chpl";
require "CryptoSupport/cryptoRandomSupport.chpl";
require "CryptoSupport/rsaSupport.chpl";

module Crypto {

  use kdfSupport;
  use kdfSupport;
  use aesSupport;
  use aesSupport;
  use hashSupport;
  use hashSupport;
  use CryptoUtils;
  use CryptoUtils;
  use cryptoRandomSupport;
  use cryptoRandomSupport;
  use rsaSupport;
  use rsaSupport;
  use symmetricPrimitives;
  use symmetricPrimitives;
  use asymmetricPrimitives;
  use asymmetricPrimitives;

  /* Hashing Functions */
  class Hash {
    var hashLen: int;
    var digestName: string;
    var hashDomain: domain(1);
    var hashSpace: [hashDomain] uint(8);

    /* Hash digest constructor that initializes the algorithm */
    proc Hash(digestName: string) {
      select digestName {
        when "MD5"        do this.hashLen = 16;
        when "SHA1"       do this.hashLen = 20;
        when "SHA224"     do this.hashLen = 28;
        when "SHA256"     do this.hashLen = 32;
        when "SHA384"     do this.hashLen = 48;
        when "SHA512"     do this.hashLen = 64;
        when "RIPEMD160"  do this.hashLen = 20;
        otherwise do halt("A digest with the name \'" + digestName + "\' doesn't exist.");
      }
      this.digestName = digestName;
      this.hashDomain = {0..this.hashLen-1};
    }

    /* Returns the name of the digest algorithm in use */
    proc getDigestName() {
      return this.digestName;
    }

    /* Returns the buffer of the hash */
    proc getDigest(inputBuffer: CryptoBuffer) {
      this.hashSpace = hashSupport.digestPrimitives(this.digestName, this.hashLen, inputBuffer);
      var hashBuffer = new CryptoBuffer(this.hashSpace);
      return hashBuffer;
    }
  }


  /* AES Symmetric cipher */
  class AES {
    var cipher: symmetricPrimitives.EVP_CIPHER_PTR;
    var bitLen: int;

    proc AES(bits: int, mode: string) {
      if (bits == 128 && mode == "cbc") {
        this.cipher = symmetricPrimitives.EVP_aes_128_cbc();
      } else if (bits == 192 && mode == "cbc") {
        this.cipher = symmetricPrimitives.EVP_aes_192_cbc();
      } else if (bits == 256 && mode == "cbc") {
        this.cipher = symmetricPrimitives.EVP_aes_256_cbc();
      } else {
        halt("The desired variant of AES does not exist.");
      }
      this.bitLen = bits/8;
    }

    /* Returns the number of bytes required by the cipher */
    proc getByteSize() {
        return this.bitLen;
    }

    /* AES encryption routine */
    proc encrypt(plaintext: CryptoBuffer, key: CryptoBuffer, IV: CryptoBuffer) {
      var encryptedPlaintext = aesSupport.aesEncrypt(plaintext, key, IV, this.cipher);
      var encryptedPlaintextBuff = new CryptoBuffer(encryptedPlaintext);
      return encryptedPlaintextBuff;
    }

    /* AES decryption routine */
    proc decrypt(ciphertext: CryptoBuffer, key: CryptoBuffer, IV: CryptoBuffer) {
      var decryptedCiphertext = aesSupport.aesDecrypt(ciphertext, key, IV, this.cipher);
      var decryptedCiphertextBuff = new CryptoBuffer(decryptedCiphertext);
      return decryptedCiphertextBuff;
    }
  }

  class CryptoRandom {
    proc createRandomBuffer(buffLen: int) {
      var randomizedBuff = cryptoRandomSupport.createRandomBuffer(buffLen);
      var randomizedCryptoBuff = new CryptoBuffer(randomizedBuff);
      return randomizedCryptoBuff;
    }
  }

  class KDF {
    var bitLen: int;
    var iterCount: int;
    var hashName: string;

    proc KDF(bitLen: int, iterCount: int, digest: Hash) {
      this.bitLen = bitLen;
      this.iterCount = iterCount;
      this.hashName = digest.getDigestName();
    }

    proc PBKDF2_HMAC(userKey: string, saltBuff: CryptoBuffer) {
      var key = kdfSupport.PBKDF2_HMAC(userKey, saltBuff, this.bitLen, this.iterCount, this.hashName);
      var keyBuff = new CryptoBuffer(key);
      return keyBuff;
    }
  }

  class RSA {

    var keySize: int;
    var keyObjSize: int;
    var keyObj: asymmetricPrimitives.EVP_PKEY_PTR;
    var ivLen: int;

    proc RSA(keySize) {
      this.keySize = keySize;
      this.keyObj = rsaSupport.rsaInit(this.keySize);
      this.ivLen = asymmetricPrimitives.EVP_CIPHER_iv_length(asymmetricPrimitives.EVP_aes_256_cbc());
      this.keyObjSize = asymmetricPrimitives.EVP_PKEY_size(this.keyObj);
    }

    proc encrypt(plaintext: CryptoBuffer) {
      var iv: [0..(this.ivLen - 1)] uint(8);
      var encSymmKey: [0..(this.keyObjSize - 1)] uint(8);
      var ciphertextDomain: domain(1) = {0..(plaintext.getBuffSize() + 16)};
      var ciphertext: [ciphertextDomain] uint(8);

      rsaSupport.rsaEncrypt(this.keyObj, plaintext, iv, encSymmKey, ciphertext, ciphertextDomain);

      var ivBuff = new CryptoBuffer(iv);
      var keyBuff = new CryptoBuffer(encSymmKey);
      var ciphertextBuff = new CryptoBuffer(ciphertext);

      var ciphertextEnvp = new Envelope(ivBuff, keyBuff, ciphertextBuff);
      return ciphertextEnvp;
    }

    proc decrypt(envelope: Envelope) {

      var encKey = envelope.getEncKey();
      var ciphertext = envelope.getEncMessage();
      var iv = envelope.getIV();

      var plaintext = rsaSupport.rsaDecrypt(this.keyObj, iv, encKey, ciphertext);
      var plaintextBuff = new CryptoBuffer(plaintext);
      return plaintextBuff;
    }
  }
}
