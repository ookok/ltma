///|
/// EngineRenderer — signal-reactive wrapper around VNodeApp.
pub struct EngineRenderer {
  app : @vnode.VNodeApp
  stop_terminal : () -> Unit
}

///|
pub fn EngineRenderer::new(
  w : Int,
  h : Int,
  output_fn : (String) -> Unit,
) -> EngineRenderer {
  let (app, stop) = @vnode.init_vnode_terminal(
    w,
    h,
    output_fn,
    mouse=true,
    raw_mode=true,
  )
  { app, stop_terminal: stop }
}

///|
pub fn EngineRenderer::render(
  self : EngineRenderer,
  root_fn : () -> @vnode.TuiNode,
) -> () -> Unit {
  self.app.create_render_effect(root_fn, fn(s) { @tui_io.print_raw(s) })
}

///|
pub fn EngineRenderer::shutdown(
  self : EngineRenderer,
  stop_effect : () -> Unit,
) -> Unit {
  stop_effect()
  (self.stop_terminal)()
}

///|
pub fn EngineRenderer::from_terminal(
  output_fn : (String) -> Unit,
) -> EngineRenderer {
  let (w, h) = @tui_io.get_terminal_size()
  EngineRenderer::new(w, h, output_fn)
}

///|
pub fn EngineRenderer::resize(self : EngineRenderer) -> Unit {
  let (w, h) = @tui_io.get_terminal_size()
  self.app.resize(w, h)
}
