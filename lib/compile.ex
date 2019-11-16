defmodule Elxcomp do
end

defmodule Compile do
  def compile(fname, def) do
    [name, _] = fname |> Atom.to_string() |> String.split(".")
    outfile = name <> ".o"
    str = compile1(def)
    File.write(outfile, "defmodule Elxcomp do\n")
    File.write(outfile, str, [:append])
    File.write(outfile, "end\n", [:append])
  end

  def compile1([]) do
    ""
  end

  def compile1([{name, dt} | dts]) do
    "def builtin([:" <>
      Atom.to_string(name) <>
      "|args],y,env,def,n) do\n" <>
      "try do\n" <>
      comp(dt, 1) <>
      "{false,env,def}\n" <>
      "catch\n" <>
      "x -> x\n" <>
      "end\n" <>
      "end\n" <>
      compile1(dts)
  end

  def comp([], _) do
    ""
  end

  def comp([x | xs], n) do
    cond do
      Elxlog.is_pred(x) -> comp_pred(x, n) <> comp(xs, n + 1)
      Elxlog.is_clause(x) -> comp_clause(x, n) <> comp(xs, n + 1)
    end
  end

  def comp_pred([_, [_ | arg]], n) do
    comp_unify(arg, n) <>
      "if env" <>
      Integer.to_string(n) <>
      " != false do\n" <>
      "if Prove.prove_all(y,env1,def,n+1) == true do\n" <>
      "throw {true,env,def}\n" <>
      "end\n" <>
      "end\n"
  end

  def comp_clause([_, [_, [_ | arg]], body], n) do
    comp_unify(arg, n) <>
      "if env" <>
      Integer.to_string(n) <>
      " != false do\n" <>
      "if Prove.prove(" <>
      comp_body(body) <>
      ",y,env2,def,n+1) == true do\n" <>
      "throw {true,env,def}\n" <>
      "end\n" <>
      "end\n"
  end

  def comp_unify(x, n) do
    "env" <> Integer.to_string(n) <> "= Prove.unify(args,[" <> arg_to_str(x) <> "],env)\n"
  end

  def comp_body(x) do
    "[" <> comp_body1(x) <> "]"
  end

  def comp_body1([b]) do
    comp_a_body(b)
  end

  def comp_body1([b | bs]) do
    comp_a_body(b) <> "," <> comp_body(bs)
  end

  def comp_a_body([:pred, [name | arg]]) do
    "[:builtin," <> "[:" <> Atom.to_string(name) <> "," <> arg_to_str(arg) <> "]]"
  end

  def comp_a_body([:builtin, [name | arg]]) do
    "[:builtin," <> "[:" <> Atom.to_string(name) <> "," <> arg_to_str(arg) <> "]]"
  end

  def arg_to_str([a]) do
    to_elixir(a)
  end

  def arg_to_str([a | as]) do
    to_elixir(a) <> "," <> arg_to_str(as)
  end

  def to_elixir(x) when is_integer(x) do
    Integer.to_string(x)
  end

  def to_elixir(x) when is_float(x) do
    Float.to_string(x)
  end

  def to_elixir(x) when is_atom(x) do
    "{:" <> Atom.to_string(x) <> ",n}"
  end

  def to_elixir([:formula, [op | arg]]) do
    "[:formula,[:" <> Atom.to_string(op) <> "," <> arg_to_str(arg) <> "]]"
  end
end