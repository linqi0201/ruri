CCCOLOR     = \033[1;38;2;254;228;208m
STRIPCOLOR  = \033[1;38;2;254;228;208m
BINCOLOR    = \033[34;1m
ENDCOLOR    = \033[0m
CC_LOG = @printf '    $(CCCOLOR)CC$(ENDCOLOR) $(BINCOLOR)%b$(ENDCOLOR)\n'
STRIP_LOG = @printf ' $(STRIPCOLOR)STRIP$(ENDCOLOR) $(BINCOLOR)%b$(ENDCOLOR)\n'
FORMATER = clang-format -i
CC = clang
STRIP = strip
CHECKER = clang-tidy --use-color
CHECK_ARG = --checks=-clang-analyzer-security.insecureAPI.strcpy,-clang-analyzer-security.insecureAPI.DeprecatedOrUnsafeBufferHandling
STRICT_CHECK_ARG = --checks=*,-clang-analyzer-security.insecureAPI.strcpy,-altera-unroll-loops,-cert-err33-c,-concurrency-mt-unsafe,-clang-analyzer-security.insecureAPI.DeprecatedOrUnsafeBufferHandling,-readability-function-cognitive-complexity,-cppcoreguidelines-avoid-magic-numbers,-readability-magic-numbers,-misc-no-recursion,-bugprone-easily-swappable-parameters,-readability-identifier-length,-cert-err34-c,-bugprone-assignment-in-if-condition,-altera*
LD_FLAGS = -lcap -lpthread
OPTIMIZE_CFLAGS = -O3 -z noexecstack -z now -fstack-protector-all -fPIE
STATIC_CFLAGS = -static -ffunction-sections -fdata-sections -Wl,--gc-sections
DEV_CFLAGS = -ggdb -Wall -Wextra -fno-stack-protector -fno-omit-frame-pointer -D__RURI_DEV__
ASAN_CFLAGS = -no-pie -O0 -fsanitize=address,leak -fsanitize-recover=address,all
SRC = ruri.c
HEADER = ruri.h
BIN_TARGET = ruri
RURI = $(SRC) -o $(BIN_TARGET)
mandoc :
	@gzip -kf doc/ruri.1
all :mandoc
	$(CC_LOG) $(BIN_TARGET)
	@$(CC) $(OPTIMIZE_CFLAGS) $(RURI) $(LD_FLAGS)
	$(STRIP_LOG) $(BIN_TARGET)
	@$(STRIP) $(BIN_TARGET)
dev :
	$(CC_LOG) $(BIN_TARGET)
	@$(CC) $(DEV_CFLAGS) $(RURI) $(LD_FLAGS)
asan :
	$(CC_LOG) $(BIN_TARGET)
	@$(CC) $(DEV_CFLAGS) $(ASAN_CFLAGS) $(RURI) $(LD_FLAGS)
static :mandoc
	$(CC_LOG) $(BIN_TARGET)
	@$(CC) $(STATIC_CFLAGS) $(OPTIMIZE_CFLAGS) $(RURI) $(LD_FLAGS)
	$(STRIP_LOG) $(BIN_TARGET)
	@$(STRIP) $(BIN_TARGET)
static-bionic :mandoc
	$(CC_LOG) $(BIN_TARGET)
	@$(CC) $(STATIC_CFLAGS) $(OPTIMIZE_CFLAGS) $(RURI) -lcap
	$(STRIP_LOG) $(BIN_TARGET)
	@$(STRIP) $(BIN_TARGET)
install :all
	install -m 777 $(BIN_TARGET) ${PREFIX}/bin/$(BIN_TARGET)
	install -m 777 doc/ruri.1.gz `man -w ls|head -1|sed -e "s/ls.*//"`
check :
	@printf "\033[1;38;2;254;228;208mCheck list:\n"
	@sleep 1.5s
	@$(CHECKER) $(CHECK_ARG) --list-checks $(SRC) -- $(DEV_CFLAGS) $(RURI) $(LD_FLAGS)
	@printf ' \033[1;38;2;254;228;208mCHECK\033[0m \033[34;1m%b\033[0m\n' $(SRC)
	@$(CHECKER) $(CHECK_ARG) $(SRC) -- $(LD_FLAGS)
	@printf ' \033[1;38;2;254;228;208mDONE.\n'
strictcheck :
	@printf "\033[1;38;2;254;228;208mCheck list:\n"
	@sleep 1.5s
	@$(CHECKER) $(STRICT_CHECK_ARG) --list-checks $(SRC) -- $(DEV_CFLAGS) $(RURI) $(LD_FLAGS)
	@printf ' \033[1;38;2;254;228;208mCHECK\033[0m \033[34;1m%b\033[0m\n' $(SRC)
	@$(CHECKER) $(STRICT_CHECK_ARG) $(SRC) -- $(LD_FLAGS)
	@printf ' \033[1;38;2;254;228;208mDONE.\n'
format :
	$(FORMATER) $(SRC)
	$(FORMATER) $(HEADER)
clean :
	rm ruri||true
help :
	@printf "\033[1;38;2;254;228;208mUsage:\n"
	@echo "  make all           :compile"
	@echo "  make install       :install ruri to \$$PREFIX"
	@echo "  make static        :static compile,with musl or glibc"
	@echo "  make static-bionic :static compile,with bionic"
	@echo "  make clean         :clean"
	@echo "Only for developers:"
	@echo "  make dev           :compile without optimizations, enable gdb debug information and extra logs."
	@echo "  make asan          :enable ASAN"
	@echo "  make check         :run clang-tidy"
	@echo "  make strictcheck   :run clang-tidy for more checks"
	@echo "  make format        :format code"
	@echo "*Premature optimization is the root of all evil."
	@echo "Dependent libraries:"
	@echo "  libpthread,libcap"
