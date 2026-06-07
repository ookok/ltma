///|
/// Theme — color scheme and spacing presets.
pub struct Theme {
  name : String
  primary : String
  secondary : String
  accent : String
  surface : String
  surface_alt : String
  text : String
  text_dim : String
  text_bright : String
  error : String
  success : String
  warning : String
  border : String
  code_bg : String
  spacing : Int
}

///|
pub fn Theme::dark() -> Theme {
  {
    name: "dark",
    primary: "cyan",
    secondary: "blue",
    accent: "magenta",
    surface: "rgb(15,15,20)",
    surface_alt: "rgb(25,25,35)",
    text: "rgb(220,220,230)",
    text_dim: "rgb(120,120,140)",
    text_bright: "white",
    error: "red",
    success: "green",
    warning: "yellow",
    border: "rgb(80,80,100)",
    code_bg: "rgb(20,20,30)",
    spacing: 1,
  }
}

///|
pub fn Theme::light() -> Theme {
  {
    name: "light",
    primary: "blue",
    secondary: "cyan",
    accent: "magenta",
    surface: "rgb(250,250,252)",
    surface_alt: "rgb(240,240,245)",
    text: "rgb(40,40,50)",
    text_dim: "rgb(140,140,150)",
    text_bright: "black",
    error: "red",
    success: "green",
    warning: "orange",
    border: "rgb(200,200,210)",
    code_bg: "rgb(245,245,248)",
    spacing: 1,
  }
}
