"""Makes the start-screen sounds (no recordings, so no licences):
  pencil.wav  crayon/pencil scratching, short strokes for about 3.5 s
  pop.wav     a soft "pop" with a little sparkle when the fairy is done
Run: python3 tool/make_sounds.py  (writes assets/sounds/)."""
import math, random, struct, wave, os

RATE = 22050
random.seed(7)

def write(name, samples):
    os.makedirs('assets/sounds', exist_ok=True)
    with wave.open(f'assets/sounds/{name}', 'wb') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(RATE)
        w.writeframes(b''.join(struct.pack('<h', max(-32767, min(32767, int(s * 32767)))) for s in samples))

def pencil(seconds=3.6):
    out = [0.0] * int(RATE * seconds)
    t = 0.04
    while t < seconds - 0.1:
        dur = random.uniform(0.07, 0.22)          # one stroke
        start = int(t * RATE); n = int(dur * RATE)
        prev = 0.0; lp = 0.0
        grain = random.uniform(0.5, 0.9)
        for i in range(n):
            env = math.sin(math.pi * i / n) ** 0.6   # soft in and out
            x = random.uniform(-1, 1)
            hp = x - prev; prev = x                  # bright, papery
            lp += 0.35 * (hp - lp)                   # but not hissy
            rasp = 0.6 + 0.4 * math.sin(2 * math.pi * random.uniform(18, 30) * i / RATE)
            if start + i < len(out):
                out[start + i] += lp * env * rasp * 0.32 * grain
        t += dur + random.uniform(0.02, 0.09)       # lift the pencil
    return out

def pop(seconds=0.55):
    n = int(RATE * seconds); out = []
    for i in range(n):
        t = i / RATE
        f = 380 + 1100 * (1 - math.exp(-t * 28))    # quick upward "뿅"
        body = math.sin(2 * math.pi * f * t) * math.exp(-t * 9) * 0.55
        sparkle = sum(math.sin(2 * math.pi * h * t) for h in (2093, 2637, 3136)) / 3 * \
            (math.exp(-(t - 0.12) * 14) if t > 0.12 else 0) * 0.18
        out.append(body + sparkle)
    return out

write('pencil.wav', pencil())
write('pop.wav', pop())
print('wrote assets/sounds/pencil.wav, pop.wav')
