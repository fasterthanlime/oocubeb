include cubeb/cubeb

CubeResultCode: enum {
  OK: extern(CUBEB_OK)
  ERROR: extern(CUBEB_ERROR)
  ERROR_INVALID_FORMAT: extern(CUBEB_ERROR_INVALID_FORMAT)
}

CubeSampleFormat: enum /* from cubeb_sample_format */ {
  /*< Little endian 16-bit signed PCM. */
  S16LE: extern(CUBEB_SAMPLE_S16LE)

  /*< Big endian 16-bit signed PCM. */
  S16BE: extern(CUBEB_SAMPLE_S16LE)

  /*< Native endian 16-bit signed PCM. */
  S16NE: extern(CUBEB_SAMPLE_S16NE)

  /*< Little endian 32-bit IEEE floating point PCM. */
  FLOAT32LE: extern(CUBEB_SAMPLE_FLOAT32LE)

  /*< Big endian 32-bit IEEE floating point PCM. */
  FLOAT32BE: extern(CUBEB_SAMPLE_FLOAT32BE)

  /*< Native endian 32-bit IEEE floating point PCM. */
  FLOAT32NE: extern(CUBEB_SAMPLE_FLOAT32NE)
}

CubeState: enum /* from cubeb_state */ {
  /* Stream started. */
  STARTED: extern(CUBEB_STATE_STARTED)
  /* Stream stopped. */
  STOPPED: extern(CUBEB_STATE_STOPPED)
  /* Stream drained. */
  DRAINED: extern(CUBEB_STATE_DRAINED)
  /* Stream disabled due to error. */
  ERROR:   extern(CUBEB_STATE_ERROR)
}

CubeStreamParams: cover from cubeb_stream_params {
  format: extern CubeSampleFormat
  rate: UInt
  channels: UInt
}

CubeContext: cover from cubeb* {

  new: static func (contextName: String) -> This {
    ctx: This
    match (cubeb_init(ctx&, contextName)) {
      case CubeResultCode OK =>
        ctx
      case =>
        null // an error happened
    }
  }

  getBackendId: func -> String {
    cubeb_get_backend_id(this) toString()
  }

  destroy: extern(cubeb_destroy) func

}

cubeb_init: extern func (CubeContext*, CString) -> Int
cubeb_get_backend_id: extern func (CubeContext) -> CString

data_callback_thunk: func (_stream: _CubeStream, stream: CubeStream,
  buffer: Pointer, nframes: Long) {
  stream refill(buffer, nframes)
}

state_callback_thunk: func (_stream: CubeStream, stream: CubeStream,
  state: CubeState) {
  stream stateChange(state)
}

_CubeStream: cover from cubeb_stream*

CubeStream: class {

  _stream: _CubeStream

  /* Initialize a stream associated with the supplied application context. */
  init: func (context: CubeContext, name: String, params: CubeStreamParams, latency: UInt) {
    cubeb_stream_init(context, _stream&, name, params,
        latency, data_callback_thunk as Pointer, state_callback_thunk as Pointer, this)
  }

  /* Destroy a stream. */
  destroy: func {
    cubeb_stream_destroy(_stream)
  }

  /* Start playback. */
  start: func {
    cubeb_stream_start(_stream)
  }

  /* Stop playback. */
  stop: func {
    cubeb_stream_stop(_stream)
  }

  /* Get the current stream playback position. */
  getPosition: func -> UInt64 {
    pos: UInt64
    cubeb_stream_get_position(_stream, pos&)
    pos
  }

  /*
   * To be overriden by users
   */
  stateChange: func (state: CubeState)

  /*
   * To be overriden by users
   *
   * @returns the number of frames filled
   */
  refill: func (buffer: Pointer, nframes: Long) -> Long {
     0
  }

}

cubeb_stream_init: extern func (CubeContext, _CubeStream*, CString, CubeStreamParams,
  UInt, Pointer, Pointer, Pointer)

cubeb_stream_start: extern func (_CubeStream) -> CubeResultCode
cubeb_stream_stop: extern func (_CubeStream) -> CubeResultCode
cubeb_stream_destroy: extern func (_CubeStream) -> CubeResultCode
cubeb_stream_get_position: extern func (_CubeStream, UInt64*) -> CubeResultCode

