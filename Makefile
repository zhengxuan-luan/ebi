default:
	vcs +vcs+lic+wait -sverilog -kdb +vc+list +vpi \
		+error+20 +lint=TFIPC-L +lint=IIMW-L +lint=GCWM-L +lint=CAWM-L  +lint=PCWM-L -full64 -F flist.f -top ebi_tb -timescale=1ns/1ps \
		-v2k_generate -debug_access+all

run:
	-mkdir ./logs
	time ./simv 2>&1 | tee run_2.log

wave:
	Verdi-SX -ssf ./logs/waves.fsdb

clean:
	-rm bld.log simv ucli.key waves.*
	-rm -r csrc simv.daidir logs Verdi-SXLog
	-rm *.log
	-rm novas* .nfs* 