//Generate a random seed
rnd_seed = Math.floor(Math.random() * 1000000000);
rnd_seed_s = Math.floor(Math.random() * 1000000000);

function rnd_9s() {
  rnd_seed += 1;
  return crc32(rnd_seed, rnd_seed_s);
}
