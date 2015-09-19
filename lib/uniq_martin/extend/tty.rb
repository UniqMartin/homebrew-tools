module UniqMartin
  module TtyExtension
    def purple
      bold 35
    end
  end
end

Tty.extend(UniqMartin::TtyExtension)
