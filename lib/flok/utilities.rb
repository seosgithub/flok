module Flok
  def self.system! cmd
    res = system(cmd)
    out = ""
    out << "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@\n"
    out << "SHELL ERROR\n"
    out << "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@\n\n"
      out << "\t(user@localhost) #{cmd}\n"
      out << "\t(user@localhost) echo $?\n"
      out << "\t#{res}\n"
      out << "\t(user@localhost) pwd\n\t"
      out << `pwd`
    out << "\n@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@\n"
    raise out unless res
  end
end
