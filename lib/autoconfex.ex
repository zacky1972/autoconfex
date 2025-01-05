defmodule Autoconfex do
  @moduledoc """
  Autoconfex: Auto-configuration of NIFs in C for Elixir.
  """

  @doc """
  Returns `true` if the given `c_compiler` can compile the given `source_code` with the given `options`.

  `c_compiler` assumes to be option-compatible with GCC and Clang.

  ## Examples

      iex> Autoconfex.compilable_by_cc?(
      ...>   "gcc",
      ...>   \"""
      ...>   int main(int argc, char *argv[])
      ...>   {
      ...>      return 0;
      ...>   }
      ...>   \"""
      ...> )
      true
  """
  @spec compilable_by_cc?(binary(), binary(), list(binary())) :: boolean()
  def compilable_by_cc?(c_compiler, source_code, options \\ []) do
    base_root = :crypto.strong_rand_bytes(10) |> Base.encode32(case: :lower)
    base = base_root <> ".c"

    base_args =
      [
        "-Werror",
        "-Wall",
        base,
        "-o",
        base_root
      ]

    compilable?(c_compiler, base, source_code, options ++ base_args)
  end

  @doc """
  Returns `true` if the given `executable` can compile the given `source_code`,
  which will be created on the path joining `/tmp` and `base`, with the given `args`.
  """
  @spec compilable?(binary(), binary(), binary(), list(binary())) :: boolean()
  def compilable?(executable, base, source_code, args) do
    case File.write(Path.join("/tmp", base), source_code) do
      :ok ->
        case execute(executable, args, cd: "/tmp", stderr_to_stdout: true) do
          {_, 0} -> true
          _ -> false
        end

      _ ->
        false
    end
  end

  @doc ~S"""
  Execute the given `executable` with `args`, if the `executable` can be located on the system.

  `executable` is expected to be an executable available in PATH unless an absolute path is given.

  `args` must be a list of binaries which the executable will receive as its arguments as is.
  This means that:

  * environment variables will not be interpolated
  * wildcard expansion will not happen (unless `Path.wildcard/2` is used explicitly)
  * arguments do not need to be escaped or quoted for shell safety

  This function returns a tuple containing the collected result and the command exit status.

  Internally, this function uses a `Port` for interacting with the outside world.
  However, if you plan to run a long-running program, ports guarantee stdin/stdout devices will be closed
  but it does not automatically terminate the program.
  The documentation for the `Port` module describes this problem and possible solutions
  under the "Zombie processes" section.

  > #### Windows argument splitting and untrusted arguments {: .warning}
  >
  > On Unix systems, arguments are passed to a new operating system
  > process as an array of strings but on Windows it is up to the child
  > process to parse them and some Windows programs may apply their own
  > rules, which are inconsistent with the standard C runtime `argv` parsing
  >
  > This is particularly troublesome when invoking `.bat` or `.com` files
  > as these run implicitly through `cmd.exe`, whose argument parsing is
  > vulnerable to malicious input and can be used to run arbitrary shell
  > commands.
  >
  > Therefore, if you are running on Windows and you execute batch
  > files or `.com` applications, you must not pass untrusted input as
  > arguments to the program. You may avoid accidentally executing them
  > by explicitly passing the extension of the program you want to run,
  > such as `.exe`, and double check the program is indeed not a batch
  > file or `.com` application.

  ## Options

    * `:into` - injects the result into the given collectable, defaults to `""`

    * `:lines` - (since v1.15.0) reads the output by lines instead of in bytes. It expects a
      number of maximum bytes to buffer internally (1024 is a reasonable default).
      The collectable will be called with each finished line (regardless of buffer
      size) and without the EOL character

    * `:cd` - the directory to run the command in

    * `:env` - an enumerable of tuples containing environment key-value as
      binary. The child process inherits all environment variables from its
      parent process, the Elixir application, except those overwritten or
      cleared using this option. Specify a value of `nil` to clear (unset) an
      environment variable, which is useful for preventing credentials passed
      to the application from leaking into child processes

    * `:arg0` - sets the command arg0

    * `:stderr_to_stdout` - redirects stderr to stdout when `true`, no effect
      if `use_stdio` is `false`.

    * `:use_stdio` - `true` by default, setting it to false allows direct
      interaction with the terminal from the callee

    * `:parallelism` - when `true`, the VM will schedule port tasks to improve
      parallelism in the system. If set to `false`, the VM will try to perform
      commands immediately, improving latency at the expense of parallelism.
      The default is `false`, and can be set on system startup by passing the
      [`+spp`](https://www.erlang.org/doc/man/erl.html#+spp) flag to `--erl`.
      Use `:erlang.system_info(:port_parallelism)` to check if enabled.

  ## Error reasons

  If invalid arguments are given, `ArgumentError` is raised by
  `System.cmd/3`. `System.cmd/3` also expects a strict set of
  options and will raise if unknown or invalid options are given.

  Furthermore, `System.cmd/3` may fail with one of the POSIX reasons
  detailed below:

    * `:system_limit` - all available ports in the Erlang emulator are in use

    * `:enomem` - there was not enough memory to create the port

    * `:eagain` - there are no more available operating system processes

    * `:enametoolong` - the external command given was too long

    * `:emfile` - there are no more available file descriptors
      (for the operating system process that the Erlang emulator runs in)

    * `:enfile` - the file table is full (for the entire operating system)

    * `:eacces` - the command does not point to an executable file

    * `:enoent` - the command does not point to an existing file
  """
  @spec execute(binary(), any()) :: false | {any(), non_neg_integer()}
  def execute(executable, args, opts \\ []) do
    case System.find_executable(executable) do
      nil -> false
      executable -> System.cmd(executable, args, opts)
    end
  end
end
