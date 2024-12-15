import os
import sys

if __name__ == "__main__":
    bad_flags = os.getenv("FILTER_COMPILE_COMMANDS_FLAGS", "").split(",")
    compile_commands = sys.argv[1]
    with open(compile_commands, "r") as f:
        lines = f.readlines()

    with open(compile_commands, "w") as f:
        for line in lines:
            # find flag in line
            for flag in bad_flags:
                if flag not in line:
                    continue

                begin = line.find(flag)
                if begin == -1:
                    continue
                end = line[begin:-1].find(" -")
                if end != -1:
                    end += begin
                line = line[:begin] + line[end + 1 :]

            f.write(line)
