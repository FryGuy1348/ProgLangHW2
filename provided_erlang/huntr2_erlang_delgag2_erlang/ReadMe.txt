Names: Ryan Hunt (huntr2) & Geremy Delgado (delgag2)
Date to be submitted: 10/31/2021
Homework #2: Distributed File Sharing
Language - Erlang (OTP 24)

Bugs/Issues - None at the moment. There are delays/timer:sleep calls in the get function to give the process time to gather files, so it may take a second or two for the files to appear in the downloads folder.
Created fixed_run.sh, as suggested on lms. It did run, but didn't get any of the correct results, unlike testing in erlang did.
Program/Functions work well when testing in the Erlang Shell

NOTE: Please run manually in erlang shell if at all possible (if start_dir_service gives issues, do c(main). and run again to fix)
