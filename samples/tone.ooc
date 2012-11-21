use cubeb
import cubeb

import math, os/Time

SAMPLE_FREQUENCY := 48_000

Sine: class extends CubeStream {

  position := 0

  init: func (context: CubeContext) {
    params: CubeStreamParams
    params format = CubeSampleFormat S16NE
    params rate = SAMPLE_FREQUENCY
    params channels = 1

    super(context, "Cubeb tone (mono)", params, 250)
  }   

  stateChange: func (state: CubeState) {
    match state {
      case CubeState STARTED =>
        "stream started" println()
      case CubeState STOPPED =>
        "stream stopped" println()
      case CubeState DRAINED =>
        "stream drained" println()
      case =>
        "unknown stream state" println()
    }
  }

  refill: func (buffer: Short*, nframes: Long) -> Long {

    for (i in 0..nframes) {
        /* North American dial tone */
        buffer[i]  = 16000 * sin(2 * PI * (i + position) * 350 / SAMPLE_FREQUENCY) +
                     16000 * sin(2 * PI * (i + position) * 440 / SAMPLE_FREQUENCY)
    } 

    position += nframes
 
    nframes 

  }

}

main: func {

  context := CubeContext new("Cubeb tone example")
  if (!context) {
    "Error initializing cubeb stream" println()
    exit(-1)
  }

  stream := Sine new(context)

  stream start()
  Time sleepSec(1)
  stream stop()

  stream destroy()
  context destroy()

}

