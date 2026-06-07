///|
test "SimpleTemplate renders variables" {
  let t = SimpleTemplate::new("Hello {name}, you are {role}.")
  let result = t.render(Map([("name", "Alice"), ("role", "admin")]))
  assert_eq(result, "Hello Alice, you are admin.")
}

///|
test "PromptBuilder builds messages" {
  let pb = PromptBuilder::new("System: You are {name}.")
    .with_var("name", "Bot")
    .add_user("Hello!")
    .add_assistant("Hi there!")
  let msgs = pb.build()
  assert_eq(msgs.length(), 3)
  assert_eq(msgs[0].content, "System: You are Bot.")
  assert_eq(msgs[1].content, "Hello!")
  assert_eq(msgs[2].content, "Hi there!")
}

///|
test "SkillRegistry register and list" {
  let reg = SkillRegistry::new()
  reg.register(Skill::new("test", "Test skill", "content here"))
  assert_eq(reg.list().length(), 1)
  let s = reg.load("test")
  assert_true(s is Some(_))
}

///|
test "Tool context prompt" {
  let reg = @tool.ToolRegistry::new()
  reg.register(@core.ToolDefinition::create("echo", "Echo back", "", false), fn(
    i,
  ) {
    i
  })
  let ctx = tool_context_prompt(reg)
  assert_true(ctx.contains("echo"))
  assert_true(ctx.contains("Echo"))
}
