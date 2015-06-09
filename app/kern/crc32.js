function crc_init() {
  var c;
  crc_table = [];
  for (var n = 0; n < 256; n++) {
    c = n;
    for (var k = 0; k < 8; k++) {
      c = ((c & 1) ? (0xEDB88320 ^ (c >>> 1)) : (c >>> 1));
    }
    crc_table[n] = c;
  }
}
crc_init();

function crc32(seed, str) {
  var crc = seed ^ (-1);

  for (var i = 0; i < str.length; i++) {
    crc = (crc >>> 8) ^ crc_table[(crc ^ str.charCodeAt(i)) & 0xFF];
  }

  return (crc ^ (-1)) >>> 0;
};
