proc main() {
  use Crypto;
  var x: [0..10] uint(8);
  var a = new CryptoBuffer(x);
  writeln(a.toHex()); // prints 0 due to uninitialized values
}
