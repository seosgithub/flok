//Generate a random seed
gen_seed = Math.floor(Math.random() * 1000000000);
gen_seed_s = Math.floor(Math.random() * 1000000000);

function gen_id() {
  gen_seed += 1;
  return crc32(gen_seed, gen_seed_s).toString();
}
