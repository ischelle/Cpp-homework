#!/bin/bash
fail_bit=0 #represents a binary form of the errors from 0 to 7, compilation error is MSB, race error is LSB.
# example: 3 is 011 in binary, which means compilation worked, memory leak failed, race error failed


first_arg=$1
second_arg=$2
shift
shift

#CHECK DIRECTORY FOR Makefile
filename=$(find "$first_arg" -maxdepth 1 -name 'Makefile*' -not -name 'Makefile~') #finds the file, returns an empty string if not found
if [[ $filename != "" ]]; then
	echo "The file: $filename exists"
else
	echo "The file doesn't exist"
	exit $fail_bit
fi

#COMPILE PROGRAM
if sudo clang++ -g -std=c++11 -pthread $second_arg -o $second_arg.out; then
	compiled="SUCCESS"
else

	compiled="FAIL"
echo "Compilation "$compiled
	fail_bit=$(( $fail_bit + 4 ))
	exit $fail_bit # 100, we didn't check the other ones yet
fi

echo $compiled

./$second_arg.out $1 # first script is shifted towards 3rd arguments



#VALGRIND RUN, WILL THROW AN ERROR CODE 55
leak=$(valgrind --leak-check=full --error-exitcode=254 ./$second_arg.out "$@" >/dev/null; echo $?)
if (( $leak == 254 ));then
	mem_leak="FAIL"
	fail_bit=$(( $fail_bit + 2 ))
else
	mem_leak="SUCCESS"
fi

#sh -c 'command "$@"; exit_code=$?; if [ $exit_code -lt 128 ]; then exit 0; else exit $exit_code; fi' sh $program $arguments


valgrind --error-exitcode=245 --tool=helgrind ./$second_arg.out "$@"; return_code=$?;
if (( $return_code == 245 ));then
	thread_leak="FAIL"
	fail_bit=$(( $fail_bit + 1 ))
else
	thread_leak="SUCCESS"
fi

echo "Compilation|Memory leaks|Thread race"
echo "$compiled|$mem_leak|$thread_leak"

exit $fail_bit
