if defined?(BetterErrors)
  BetterErrors.editor = proc { |file, line|
    "windsurf://file/%{file}:%{line}" % { file: URI.encode_www_form_component(file), line: line }
  }
end