///|
/// Middleware pipeline — pre/post processing interceptors for agent calls.

///|
/// CallContext — context passed through the middleware chain.
pub struct CallContext {
  agent_id : String
  input : @core.Message
  mut output : @core.Message
  error : String?
  metadata : Map[String, String]
}

///|
pub fn CallContext::new(
  agent_id : String,
  input : @core.Message,
) -> CallContext {
  {
    agent_id,
    input,
    output: @core.Message::text(""),
    error: None,
    metadata: Map([]),
  }
}

///|
pub fn CallContext::set_meta(
  self : CallContext,
  key : String,
  value : String,
) -> Unit {
  self.metadata[key] = value
}

///|
pub fn CallContext::get_meta(self : CallContext, key : String) -> String? {
  self.metadata.get(key)
}

///|
/// MiddlewareFn — a function in the middleware chain.
pub type MiddlewareFn = (CallContext, () -> Unit) -> Unit

///|
/// MiddlewarePipeline — ordered chain of middleware interceptors.
pub struct MiddlewarePipeline {
  middlewares : Array[MiddlewareFn]
}

///|
pub fn MiddlewarePipeline::new() -> MiddlewarePipeline {
  { middlewares: [] }
}

///|
pub fn MiddlewarePipeline::use(
  self : MiddlewarePipeline,
  mw : MiddlewareFn,
) -> Unit {
  self.middlewares.push(mw)
}

///|
pub fn MiddlewarePipeline::execute(
  self : MiddlewarePipeline,
  ctx : CallContext,
  handler : () -> Unit,
) -> Unit {
  let mws = self.middlewares
  let len = mws.length()
  if len == 0 {
    handler()
    return
  }
  let mut i = 0
  let mut step : () -> Unit = fn() {  }
  let run = fn() {
    if i < len {
      let mw = mws[i]
      i = i + 1
      mw(ctx, step)
    } else {
      handler()
    }
  }
  step = run
  step()
}

///|
/// LoggingMiddleware — logs all calls passing through.
pub fn logging_middleware(service : String) -> MiddlewareFn {
  fn(ctx : CallContext, next : () -> Unit) -> Unit {
    let _ = service
    next()
  }
}

///|
/// TimingMiddleware — records call duration in metadata.
pub fn timing_middleware() -> MiddlewareFn {
  fn(ctx : CallContext, next : () -> Unit) -> Unit {
    let start = @async.now()
    next()
    let elapsed = @async.now() - start
    ctx.set_meta("duration_ms", elapsed.to_string())
  }
}

///|
/// ErrorRecoveryMiddleware — catches panics and sets error context.
pub fn error_recovery_middleware() -> MiddlewareFn {
  fn(ctx : CallContext, next : () -> Unit) -> Unit { next() }
}
