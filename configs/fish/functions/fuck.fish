function fuck
    if not functions -q __fuck_init
        thefuck --alias | source
        function __fuck_init
        end
    end
    __fuck_alias $argv
end
