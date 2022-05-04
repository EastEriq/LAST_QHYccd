
#tail +28 matlab__20220428104808_stdout.log |\
#  csplit -z -f c26c_single_stdout -b "_%02d.log" - "/\s\s\s\s\s\*/" "{*}"

#tail +18 matlab__20220428104808_stderr.log |\
#  csplit -z -f c26c_single_stderr -b "_%02d.log" - "/InitQHYCCD|START/" "{*}"

tail +4 matlab__20220428150025_stderr.log |\
  csplit -z -f c26c_single_stderr -b "_%02d.log" - "/####/" "{*}"

tail +4 matlab__20220428150416_stderr.log |\
  csplit -z -f c26c_live_stderr -b "_%02d.log" - "/####/" "{*}"

tail +4 matlab__20220428150829_stderr.log |\
  csplit -z -f 8eab_single_stderr -b "_%02d.log" - "/####/" "{*}"

tail +4 matlab__20220428151158_stderr.log |\
  csplit -z -f 8eab_live_stderr -b "_%02d.log" - "/####/" "{*}"


tail +19 matlab__20220428150025_stdout.log |\
  csplit -z -f c26c_single_stdout -b "_%02d.log" - "/####/" "{*}"

tail +19 matlab__20220428150416_stdout.log |\
  csplit -z -f c26c_live_stdout -b "_%02d.log" - "/####/" "{*}"

tail +19 matlab__20220428150829_stdout.log |\
  csplit -z -f 8eab_single_stdout -b "_%02d.log" - "/####/" "{*}"

tail +19 matlab__20220428151158_stdout.log |\
  csplit -z -f 8eab_live_stdout -b "_%02d.log" - "/####/" "{*}"

