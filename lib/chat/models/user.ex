defmodule Chat.Models.User do
  defstruct [:user, :connection]

  @type t() :: %__MODULE__{
          user: %Chat.GroupMember{} | %Chat.User{},
          connection: pid() | nil
        }
end
