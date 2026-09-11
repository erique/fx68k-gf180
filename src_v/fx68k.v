module fx68k (
	clk,
	HALTn,
	extReset,
	pwrUp,
	enPhi1,
	enPhi2,
	eRWn,
	ASn,
	LDSn,
	UDSn,
	E,
	VMAn,
	FC0,
	FC1,
	FC2,
	BGn,
	oRESETn,
	oHALTEDn,
	DTACKn,
	VPAn,
	BERRn,
	BRn,
	BGACKn,
	IPL0n,
	IPL1n,
	IPL2n,
	iEdb,
	oEdb,
	eab
);
	reg _sv2v_0;
	input clk;
	input HALTn;
	input extReset;
	input pwrUp;
	input enPhi1;
	input enPhi2;
	output wire eRWn;
	output wire ASn;
	output wire LDSn;
	output wire UDSn;
	output reg E;
	output wire VMAn;
	output wire FC0;
	output wire FC1;
	output wire FC2;
	output wire BGn;
	output wire oRESETn;
	output wire oHALTEDn;
	input DTACKn;
	input VPAn;
	input BERRn;
	input BRn;
	input BGACKn;
	input IPL0n;
	input IPL1n;
	input IPL2n;
	input [15:0] iEdb;
	output wire [15:0] oEdb;
	output wire [23:1] eab;
	wire [4:0] Clks;
	assign Clks[4] = clk;
	assign Clks[3] = extReset;
	assign Clks[2] = pwrUp;
	assign Clks[1] = enPhi1;
	assign Clks[0] = enPhi2;
	wire wClk;
	reg [31:0] tState;
	wire enT1 = (Clks[1] & (tState == 32'd4)) & ~wClk;
	wire enT2 = Clks[0] & (tState == 32'd1);
	wire enT3 = Clks[1] & (tState == 32'd2);
	wire enT4 = Clks[0] & ((tState == 32'd0) | (tState == 32'd3));
	always @(posedge Clks[4])
		if (Clks[2])
			tState <= 32'd0;
		else
			case (tState)
				32'd0:
					if (Clks[0])
						tState <= 32'd4;
				32'd1:
					if (Clks[0])
						tState <= 32'd2;
				32'd2:
					if (Clks[1])
						tState <= 32'd3;
				32'd3:
					if (Clks[0])
						tState <= 32'd4;
				32'd4:
					if (Clks[1])
						tState <= (wClk ? 32'd0 : 32'd1);
			endcase
	reg rDtack;
	reg rBerr;
	reg [2:0] rIpl;
	reg [2:0] iIpl;
	reg Vpai;
	reg BeI;
	reg Halti;
	reg BRi;
	reg BgackI;
	reg BeiDelay;
	wire BeDebounced = ~(BeI | BeiDelay);
	always @(posedge Clks[4])
		if (Clks[2]) begin
			rBerr <= 1'b0;
			BeI <= 1'b0;
		end
		else if (Clks[0]) begin
			rDtack <= DTACKn;
			rBerr <= BERRn;
			rIpl <= ~{IPL2n, IPL1n, IPL0n};
			iIpl <= rIpl;
		end
		else if (Clks[1]) begin
			Vpai <= VPAn;
			BeI <= rBerr;
			BeiDelay <= BeI;
			BgackI <= BGACKn;
			BRi <= BRn;
			Halti <= HALTn;
		end
	localparam NANO_WIDTH = 68;
	reg [67:0] nanoLatch;
	wire [67:0] nanoOutput;
	localparam UROM_WIDTH = 17;
	reg [16:0] microLatch;
	wire [16:0] microOutput;
	localparam UADDR_WIDTH = 10;
	reg [9:0] microAddr;
	wire [9:0] nma;
	localparam NADDR_WIDTH = 9;
	reg [8:0] nanoAddr;
	wire [8:0] orgAddr;
	wire rstUrom;
	microToNanoAddr microToNanoAddr(
		.uAddr(nma),
		.orgAddr(orgAddr)
	);
	nanoRom nanoRom(
		.clk(Clks[4]),
		.nanoAddr(nanoAddr),
		.nanoOutput(nanoOutput)
	);
	uRom uRom(
		.clk(Clks[4]),
		.microAddr(microAddr),
		.microOutput(microOutput)
	);
	localparam RSTP0_NMA = 'h2;
	always @(posedge Clks[4]) begin
		if (Clks[2]) begin
			microAddr <= RSTP0_NMA;
			nanoAddr <= RSTP0_NMA;
		end
		else if (enT1) begin
			microAddr <= nma;
			nanoAddr <= orgAddr;
		end
		if (Clks[3]) begin
			microLatch <= 1'sb0;
			nanoLatch <= 1'sb0;
		end
		else if (rstUrom) begin
			{microLatch[16], microLatch[15], microLatch[0]} <= 1'sb0;
			nanoLatch <= 1'sb0;
		end
		else if (enT3) begin
			microLatch <= microOutput;
			nanoLatch <= nanoOutput;
		end
	end
	wire [104:0] Nanod;
	wire [41:0] Irdecod;
	reg Tpend;
	reg intPend;
	reg pswT;
	reg pswS;
	reg [2:0] pswI;
	wire [7:0] ccr;
	wire [15:0] psw = {pswT, 1'b0, pswS, 2'b00, pswI, ccr};
	reg [15:0] ftu;
	reg [15:0] Irc;
	reg [15:0] Ir;
	reg [15:0] Ird;
	wire [15:0] alue;
	wire [15:0] Abl;
	wire prenEmpty;
	wire au05z;
	wire dcr4;
	wire ze;
	wire [9:0] a1;
	wire [9:0] a2;
	wire [9:0] a3;
	wire isPriv;
	wire isIllegal;
	wire isLineA;
	wire isLineF;
	always @(posedge Clks[4])
		if (enT1) begin
			if (Nanod[81])
				Ird <= Ir;
			else if (microLatch[0])
				Ir <= Irc;
		end
	wire [3:0] tvn;
	wire waitBusCycle;
	wire busStarting;
	wire BusRetry = 1'b0;
	wire busAddrErr;
	wire bciWrite;
	wire bgBlock;
	wire busAvail;
	wire addrOe;
	wire busIsByte = Nanod[101] & (Irdecod[32] | Irdecod[31]);
	wire aob0;
	reg iStop;
	reg A0Err;
	reg excRst;
	reg BerrA;
	reg Spuria;
	reg Avia;
	wire Iac;
	reg rAddrErr;
	reg iBusErr;
	reg Err6591;
	wire iAddrErr = rAddrErr & addrOe;
	wire enErrClk;
	assign rstUrom = Clks[1] & enErrClk;
	uaddrDecode uaddrDecode(
		.opcode(Ir),
		.a1(a1),
		.a2(a2),
		.a3(a3),
		.isPriv(isPriv),
		.isIllegal(isIllegal),
		.isLineA(isLineA),
		.isLineF(isLineF),
		.lineBmap()
	);
	sequencer sequencer(
		.Clks(Clks),
		.enT3(enT3),
		.microLatch(microLatch),
		.Ird(Ird),
		.A0Err(A0Err),
		.excRst(excRst),
		.BerrA(BerrA),
		.busAddrErr(busAddrErr),
		.Spuria(Spuria),
		.Avia(Avia),
		.Tpend(Tpend),
		.intPend(intPend),
		.isIllegal(isIllegal),
		.isPriv(isPriv),
		.isLineA(isLineA),
		.isLineF(isLineF),
		.nma(nma),
		.a1(a1),
		.a2(a2),
		.a3(a3),
		.tvn(tvn),
		.psw(psw),
		.prenEmpty(prenEmpty),
		.au05z(au05z),
		.dcr4(dcr4),
		.ze(ze),
		.alue01(alue[1:0]),
		.i11(Irc[11])
	);
	wire [16:1] sv2v_tmp_excUnit_Irc;
	always @(*) Irc = sv2v_tmp_excUnit_Irc;
	excUnit excUnit(
		.Clks(Clks),
		.Nanod(Nanod),
		.Irdecod(Irdecod),
		.enT1(enT1),
		.enT2(enT2),
		.enT3(enT3),
		.enT4(enT4),
		.Ird(Ird),
		.ftu(ftu),
		.iEdb(iEdb),
		.pswS(pswS),
		.prenEmpty(prenEmpty),
		.au05z(au05z),
		.dcr4(dcr4),
		.ze(ze),
		.AblOut(Abl),
		.eab(eab),
		.aob0(aob0),
		.Irc(sv2v_tmp_excUnit_Irc),
		.oEdb(oEdb),
		.alue(alue),
		.ccr(ccr)
	);
	nDecoder3 nDecoder(
		.Clks(Clks),
		.Nanod(Nanod),
		.Irdecod(Irdecod),
		.enT2(enT2),
		.enT4(enT4),
		.microLatch(microLatch),
		.nanoLatch(nanoLatch)
	);
	irdDecode irdDecode(
		.ird(Ird),
		.Irdecod(Irdecod)
	);
	busControl busControl(
		.Clks(Clks),
		.enT1(enT1),
		.enT4(enT4),
		.permStart(Nanod[104]),
		.permStop(Nanod[103]),
		.iStop(iStop),
		.aob0(aob0),
		.isWrite(Nanod[102]),
		.isRmc(Nanod[100]),
		.isByte(busIsByte),
		.busAvail(busAvail),
		.bciWrite(bciWrite),
		.addrOe(addrOe),
		.bgBlock(bgBlock),
		.waitBusCycle(waitBusCycle),
		.busStarting(busStarting),
		.busAddrErr(busAddrErr),
		.rDtack(rDtack),
		.BeDebounced(BeDebounced),
		.Vpai(Vpai),
		.ASn(ASn),
		.LDSn(LDSn),
		.UDSn(UDSn),
		.eRWn(eRWn)
	);
	busArbiter busArbiter(
		.Clks(Clks),
		.BRi(BRi),
		.BgackI(BgackI),
		.Halti(Halti),
		.bgBlock(bgBlock),
		.busAvail(busAvail),
		.BGn(BGn)
	);
	wire [1:0] uFc = microLatch[16:15];
	reg oReset;
	reg oHalted;
	assign oRESETn = !oReset;
	assign oHALTEDn = !oHalted;
	always @(posedge Clks[4])
		if (Clks[2]) begin
			oReset <= 1'b0;
			oHalted <= 1'b0;
		end
		else if (enT1) begin
			oReset <= (uFc == 2'b01) & !Nanod[104];
			oHalted <= (uFc == 2'b10) & !Nanod[104];
		end
	reg [2:0] rFC;
	assign {FC2, FC1, FC0} = rFC;
	assign Iac = {rFC == 3'b111};
	always @(posedge Clks[4])
		if (Clks[3])
			rFC <= 1'sb0;
		else if (enT1 & Nanod[104]) begin
			rFC[2] <= pswS;
			rFC[1] <= microLatch[16] | (~microLatch[15] & Irdecod[41]);
			rFC[0] <= microLatch[15] | (~microLatch[16] & ~Irdecod[41]);
		end
	reg [2:0] inl;
	reg updIll;
	reg prevNmi;
	wire nmi = iIpl == 3'b111;
	wire iplStable = iIpl == rIpl;
	wire iplComp = iIpl > pswI;
	always @(posedge Clks[4]) begin
		if (Clks[3]) begin
			intPend <= 1'b0;
			prevNmi <= 1'b0;
		end
		else begin
			if (Clks[0])
				prevNmi <= nmi;
			if (Clks[0]) begin
				if (iplStable & ((nmi & ~prevNmi) | iplComp))
					intPend <= 1'b1;
				else if (((inl == 3'b111) & Iac) | ((iplStable & !nmi) & !iplComp))
					intPend <= 1'b0;
			end
		end
		if (Clks[3]) begin
			inl <= 1'sb1;
			updIll <= 1'b0;
		end
		else if (enT4)
			updIll <= microLatch[0];
		else if (enT1 & updIll)
			inl <= iIpl;
		if (enT4) begin
			Spuria <= ~BeiDelay & Iac;
			Avia <= ~Vpai & Iac;
		end
	end
	assign enErrClk = iAddrErr | iBusErr;
	assign wClk = ((waitBusCycle | ~BeI) | iAddrErr) | Err6591;
	reg [3:0] eCntr;
	reg rVma;
	assign VMAn = rVma;
	wire xVma = ~rVma & (eCntr == 8);
	always @(posedge Clks[4]) begin
		if (Clks[2]) begin
			E <= 1'b0;
			eCntr <= 1'sb0;
			rVma <= 1'b1;
		end
		if (Clks[0]) begin
			if (eCntr == 9)
				E <= 1'b0;
			else if (eCntr == 5)
				E <= 1'b1;
			if (eCntr == 9)
				eCntr <= 1'sb0;
			else
				eCntr <= eCntr + 1'b1;
		end
		if (((Clks[0] & addrOe) & ~Vpai) & (eCntr == 3))
			rVma <= 1'b0;
		else if (Clks[1] & (eCntr == {4 {1'sb0}}))
			rVma <= 1'b1;
	end
	always @(posedge Clks[4]) begin
		if (Clks[3])
			rAddrErr <= 1'b0;
		else if (Clks[1]) begin
			if (busAddrErr & addrOe)
				rAddrErr <= 1'b1;
			else if (~addrOe)
				rAddrErr <= 1'b0;
		end
		if (Clks[3])
			iBusErr <= 1'b0;
		else if (Clks[1])
			iBusErr <= ((BerrA & ~BeI) & ~Iac) & !BusRetry;
		if (Clks[3])
			BerrA <= 1'b0;
		else if (Clks[0]) begin
			if ((~BeI & ~Iac) & addrOe)
				BerrA <= 1'b1;
			else if (BeI & busStarting)
				BerrA <= 1'b0;
		end
		if (Clks[3])
			excRst <= 1'b1;
		else if (enT2 & Nanod[104])
			excRst <= 1'b0;
		if (Clks[3])
			A0Err <= 1'b1;
		else if (enT3)
			A0Err <= 1'b0;
		else if ((Clks[1] & enErrClk) & (busAddrErr | BerrA))
			A0Err <= 1'b1;
		if (Clks[3]) begin
			iStop <= 1'b0;
			Err6591 <= 1'b0;
		end
		else if (Clks[1])
			Err6591 <= enErrClk;
		else if (Clks[0])
			iStop <= xVma | (Vpai & (iAddrErr | ~rBerr));
	end
	reg irdToCcr_t4;
	always @(posedge Clks[4])
		if (Clks[2]) begin
			Tpend <= 1'b0;
			{pswT, pswS, pswI} <= 1'sb0;
			irdToCcr_t4 <= 1'sb0;
		end
		else if (enT4)
			irdToCcr_t4 <= Irdecod[38];
		else if (enT3) begin
			if (Nanod[97])
				Tpend <= pswT;
			else if (Nanod[96])
				Tpend <= 1'b0;
			if (Nanod[88] & !irdToCcr_t4)
				{pswT, pswS, pswI} <= {ftu[15], ftu[13], ftu[10:8]};
			else begin
				if (Nanod[82]) begin
					pswS <= 1'b1;
					pswT <= 1'b0;
				end
				if (Nanod[89])
					pswI <= inl;
			end
		end
	reg [4:0] ssw;
	reg [3:0] tvnLatch;
	reg [15:0] tvnMux;
	reg inExcept01;
	always @(posedge Clks[4]) begin
		if (Nanod[61] & enT3)
			ssw <= {~bciWrite, inExcept01, rFC};
		if (enT1 & Nanod[81]) begin
			tvnLatch <= tvn;
			inExcept01 <= tvn != 1;
		end
		if (Clks[2])
			ftu <= 1'sb0;
		else if (enT3)
			(* full_case, parallel_case *)
			case (1'b1)
				Nanod[95]: ftu <= tvnMux;
				Nanod[87]: ftu <= {pswT, 1'b0, pswS, 2'b00, pswI, 3'b000, ccr[4:0]};
				Nanod[84]: ftu <= Ird;
				Nanod[83]: ftu[4:0] <= ssw;
				Nanod[85]: ftu <= {12'hfff, pswI, 1'b0};
				Nanod[94]: ftu <= Irdecod[22-:16];
				Nanod[91]: ftu <= Abl;
				default: ftu <= ftu;
			endcase
	end
	localparam TVN_AUTOVEC = 13;
	localparam TVN_INTERRUPT = 15;
	localparam TVN_SPURIOUS = 12;
	always @(*) begin
		if (_sv2v_0)
			;
		if (inExcept01) begin
			if (tvnLatch == TVN_SPURIOUS)
				tvnMux = 16'h0060;
			else if (tvnLatch == TVN_AUTOVEC)
				tvnMux = {11'b00000000011, pswI, 2'b00};
			else if (tvnLatch == TVN_INTERRUPT)
				tvnMux = {6'b000000, Ird[7:0], 2'b00};
			else
				tvnMux = {10'b0000000000, tvnLatch, 2'b00};
		end
		else
			tvnMux = {8'h00, Irdecod[6-:6], 2'b00};
	end
	initial _sv2v_0 = 0;
endmodule
module nDecoder3 (
	Clks,
	Irdecod,
	Nanod,
	enT2,
	enT4,
	microLatch,
	nanoLatch
);
	input wire [4:0] Clks;
	input wire [41:0] Irdecod;
	output reg [104:0] Nanod;
	input enT2;
	input enT4;
	localparam UROM_WIDTH = 17;
	input [16:0] microLatch;
	localparam NANO_WIDTH = 68;
	input [67:0] nanoLatch;
	localparam NANO_IR2IRD = 67;
	localparam NANO_TOIRC = 66;
	localparam NANO_ALU_COL = 63;
	localparam NANO_ALU_FI = 61;
	localparam NANO_TODBIN = 60;
	localparam NANO_ALUE = 57;
	localparam NANO_DCR = 57;
	localparam NANO_DOBCTRL_1 = 56;
	localparam NANO_LOWBYTE = 55;
	localparam NANO_HIGHBYTE = 54;
	localparam NANO_DOBCTRL_0 = 53;
	localparam NANO_ALU_DCTRL = 51;
	localparam NANO_ALU_ACTRL = 50;
	localparam NANO_DBD2ALUB = 49;
	localparam NANO_ABD2ALUB = 48;
	localparam NANO_DBIN2DBD = 47;
	localparam NANO_DBIN2ABD = 46;
	localparam NANO_ALU2ABD = 45;
	localparam NANO_ALU2DBD = 44;
	localparam NANO_RZ = 43;
	localparam NANO_BUSBYTE = 42;
	localparam NANO_PCLABL = 41;
	localparam NANO_RXL_DBL = 40;
	localparam NANO_PCLDBL = 39;
	localparam NANO_ABDHRECHARGE = 38;
	localparam NANO_REG2ABL = 37;
	localparam NANO_ABL2REG = 36;
	localparam NANO_ABLABD = 35;
	localparam NANO_DBLDBD = 34;
	localparam NANO_DBL2REG = 33;
	localparam NANO_REG2DBL = 32;
	localparam NANO_ATLCTRL = 29;
	localparam NANO_FTUCONTROL = 25;
	localparam NANO_SSP = 24;
	localparam NANO_RXH_DBH = 22;
	localparam NANO_AUOUT = 20;
	localparam NANO_AUCLKEN = 19;
	localparam NANO_AUCTRL = 16;
	localparam NANO_DBLDBH = 15;
	localparam NANO_ABLABH = 14;
	localparam NANO_EXT_ABH = 13;
	localparam NANO_EXT_DBH = 12;
	localparam NANO_ATHCTRL = 9;
	localparam NANO_REG2ABH = 8;
	localparam NANO_ABH2REG = 7;
	localparam NANO_REG2DBH = 6;
	localparam NANO_DBH2REG = 5;
	localparam NANO_AOBCTRL = 3;
	localparam NANO_PCH = 0;
	localparam NANO_NO_SP_ALGN = 0;
	localparam NANO_FTU_UPDTPEND = 1;
	localparam NANO_FTU_INIT_ST = 15;
	localparam NANO_FTU_CLRTPEND = 14;
	localparam NANO_FTU_TVN = 13;
	localparam NANO_FTU_ABL2PREN = 12;
	localparam NANO_FTU_SSW = 11;
	localparam NANO_FTU_RSTPREN = 10;
	localparam NANO_FTU_IRD = 9;
	localparam NANO_FTU_2ABL = 8;
	localparam NANO_FTU_RDSR = 7;
	localparam NANO_FTU_INL = 6;
	localparam NANO_FTU_PSWI = 5;
	localparam NANO_FTU_DBL = 4;
	localparam NANO_FTU_2SR = 2;
	localparam NANO_FTU_CONST = 1;
	reg [3:0] ftuCtrl;
	wire [2:0] athCtrl;
	wire [2:0] atlCtrl;
	assign athCtrl = nanoLatch[11:NANO_ATHCTRL];
	assign atlCtrl = nanoLatch[31:NANO_ATLCTRL];
	wire [1:0] aobCtrl = nanoLatch[4:NANO_AOBCTRL];
	wire [1:0] dobCtrl = {nanoLatch[NANO_DOBCTRL_1], nanoLatch[NANO_DOBCTRL_0]};
	always @(posedge Clks[4])
		if (enT4) begin
			ftuCtrl <= {nanoLatch[25], nanoLatch[26], nanoLatch[27], nanoLatch[28]};
			Nanod[80] <= !nanoLatch[NANO_AUCLKEN];
			Nanod[78-:3] <= nanoLatch[18:16];
			Nanod[79] <= nanoLatch[1:NANO_NO_SP_ALGN] == 2'b11;
			Nanod[6] <= nanoLatch[NANO_EXT_DBH];
			Nanod[5] <= nanoLatch[NANO_EXT_ABH];
			Nanod[75] <= nanoLatch[NANO_TODBIN];
			Nanod[74] <= nanoLatch[NANO_TOIRC];
			Nanod[4] <= nanoLatch[NANO_ABLABD];
			Nanod[3] <= nanoLatch[NANO_ABLABH];
			Nanod[2] <= nanoLatch[NANO_DBLDBD];
			Nanod[1] <= nanoLatch[NANO_DBLDBH];
			Nanod[73] <= atlCtrl == 3'b010;
			Nanod[70] <= atlCtrl == 3'b011;
			Nanod[72] <= atlCtrl == 3'b100;
			Nanod[71] <= atlCtrl == 3'b101;
			Nanod[62] <= athCtrl == 3'b101;
			Nanod[69] <= (athCtrl == 3'b001) | (athCtrl == 3'b101);
			Nanod[68] <= athCtrl == 3'b100;
			Nanod[67] <= athCtrl == 3'b110;
			Nanod[66] <= athCtrl == 3'b011;
			Nanod[13] <= nanoLatch[NANO_ALU2DBD];
			Nanod[12] <= nanoLatch[NANO_ALU2ABD];
			Nanod[19] <= nanoLatch[58:NANO_DCR] == 2'b11;
			Nanod[18] <= nanoLatch[59:58] == 2'b11;
			Nanod[17] <= nanoLatch[59:58] == 2'b10;
			Nanod[16] <= nanoLatch[58:NANO_ALUE] == 2'b01;
			Nanod[15] <= nanoLatch[NANO_DBD2ALUB];
			Nanod[14] <= nanoLatch[NANO_ABD2ALUB];
			Nanod[60-:2] <= dobCtrl;
		end
	wire [1:1] sv2v_tmp_AE35E;
	assign sv2v_tmp_AE35E = Nanod[62];
	always @(*) Nanod[61] = sv2v_tmp_AE35E;
	wire [1:1] sv2v_tmp_A4BAF;
	assign sv2v_tmp_A4BAF = ftuCtrl == NANO_FTU_UPDTPEND;
	always @(*) Nanod[97] = sv2v_tmp_A4BAF;
	wire [1:1] sv2v_tmp_CF9F2;
	assign sv2v_tmp_CF9F2 = ftuCtrl == NANO_FTU_CLRTPEND;
	always @(*) Nanod[96] = sv2v_tmp_CF9F2;
	wire [1:1] sv2v_tmp_923B0;
	assign sv2v_tmp_923B0 = ftuCtrl == NANO_FTU_TVN;
	always @(*) Nanod[95] = sv2v_tmp_923B0;
	wire [1:1] sv2v_tmp_F8CCE;
	assign sv2v_tmp_F8CCE = ftuCtrl == NANO_FTU_CONST;
	always @(*) Nanod[94] = sv2v_tmp_F8CCE;
	wire [1:1] sv2v_tmp_05D12;
	assign sv2v_tmp_05D12 = (ftuCtrl == NANO_FTU_DBL) | (ftuCtrl == NANO_FTU_INL);
	always @(*) Nanod[93] = sv2v_tmp_05D12;
	wire [1:1] sv2v_tmp_BD2E1;
	assign sv2v_tmp_BD2E1 = ftuCtrl == NANO_FTU_2ABL;
	always @(*) Nanod[92] = sv2v_tmp_BD2E1;
	wire [1:1] sv2v_tmp_B47FA;
	assign sv2v_tmp_B47FA = ftuCtrl == NANO_FTU_INL;
	always @(*) Nanod[89] = sv2v_tmp_B47FA;
	wire [1:1] sv2v_tmp_F1A47;
	assign sv2v_tmp_F1A47 = ftuCtrl == NANO_FTU_PSWI;
	always @(*) Nanod[85] = sv2v_tmp_F1A47;
	wire [1:1] sv2v_tmp_3B5A3;
	assign sv2v_tmp_3B5A3 = ftuCtrl == NANO_FTU_2SR;
	always @(*) Nanod[88] = sv2v_tmp_3B5A3;
	wire [1:1] sv2v_tmp_DF1EF;
	assign sv2v_tmp_DF1EF = ftuCtrl == NANO_FTU_RDSR;
	always @(*) Nanod[87] = sv2v_tmp_DF1EF;
	wire [1:1] sv2v_tmp_4FFD3;
	assign sv2v_tmp_4FFD3 = ftuCtrl == NANO_FTU_IRD;
	always @(*) Nanod[84] = sv2v_tmp_4FFD3;
	wire [1:1] sv2v_tmp_1799C;
	assign sv2v_tmp_1799C = ftuCtrl == NANO_FTU_SSW;
	always @(*) Nanod[83] = sv2v_tmp_1799C;
	wire [1:1] sv2v_tmp_08C5E;
	assign sv2v_tmp_08C5E = ((ftuCtrl == NANO_FTU_INL) | (ftuCtrl == NANO_FTU_CLRTPEND)) | (ftuCtrl == NANO_FTU_INIT_ST);
	always @(*) Nanod[82] = sv2v_tmp_08C5E;
	wire [1:1] sv2v_tmp_B6A07;
	assign sv2v_tmp_B6A07 = ftuCtrl == NANO_FTU_ABL2PREN;
	always @(*) Nanod[91] = sv2v_tmp_B6A07;
	wire [1:1] sv2v_tmp_99F51;
	assign sv2v_tmp_99F51 = ftuCtrl == NANO_FTU_RSTPREN;
	always @(*) Nanod[90] = sv2v_tmp_99F51;
	wire [1:1] sv2v_tmp_64EE2;
	assign sv2v_tmp_64EE2 = nanoLatch[NANO_IR2IRD];
	always @(*) Nanod[81] = sv2v_tmp_64EE2;
	wire [2:1] sv2v_tmp_065F0;
	assign sv2v_tmp_065F0 = nanoLatch[52:NANO_ALU_DCTRL];
	always @(*) Nanod[24-:2] = sv2v_tmp_065F0;
	wire [1:1] sv2v_tmp_65B25;
	assign sv2v_tmp_65B25 = nanoLatch[NANO_ALU_ACTRL];
	always @(*) Nanod[22] = sv2v_tmp_65B25;
	wire [3:1] sv2v_tmp_EF868;
	assign sv2v_tmp_EF868 = {nanoLatch[NANO_ALU_COL], nanoLatch[64], nanoLatch[65]};
	always @(*) Nanod[27-:3] = sv2v_tmp_EF868;
	wire [1:0] aluFinInit = nanoLatch[62:NANO_ALU_FI];
	wire [1:1] sv2v_tmp_A7F1C;
	assign sv2v_tmp_A7F1C = aluFinInit == 2'b10;
	always @(*) Nanod[20] = sv2v_tmp_A7F1C;
	wire [1:1] sv2v_tmp_E29FD;
	assign sv2v_tmp_E29FD = aluFinInit == 2'b01;
	always @(*) Nanod[21] = sv2v_tmp_E29FD;
	wire [1:1] sv2v_tmp_00B71;
	assign sv2v_tmp_00B71 = aluFinInit == 2'b11;
	always @(*) Nanod[86] = sv2v_tmp_00B71;
	wire [1:1] sv2v_tmp_CF9FA;
	assign sv2v_tmp_CF9FA = nanoLatch[NANO_ABDHRECHARGE];
	always @(*) Nanod[0] = sv2v_tmp_CF9FA;
	wire [1:1] sv2v_tmp_D4347;
	assign sv2v_tmp_D4347 = nanoLatch[21:NANO_AUOUT] == 2'b01;
	always @(*) Nanod[11] = sv2v_tmp_D4347;
	wire [1:1] sv2v_tmp_AF0C6;
	assign sv2v_tmp_AF0C6 = nanoLatch[21:NANO_AUOUT] == 2'b10;
	always @(*) Nanod[10] = sv2v_tmp_AF0C6;
	wire [1:1] sv2v_tmp_C978E;
	assign sv2v_tmp_C978E = nanoLatch[21:NANO_AUOUT] == 2'b11;
	always @(*) Nanod[9] = sv2v_tmp_C978E;
	wire [1:1] sv2v_tmp_76F18;
	assign sv2v_tmp_76F18 = aobCtrl == 2'b10;
	always @(*) Nanod[65] = sv2v_tmp_76F18;
	wire [1:1] sv2v_tmp_707E9;
	assign sv2v_tmp_707E9 = aobCtrl == 2'b01;
	always @(*) Nanod[64] = sv2v_tmp_707E9;
	wire [1:1] sv2v_tmp_69D9F;
	assign sv2v_tmp_69D9F = aobCtrl == 2'b11;
	always @(*) Nanod[63] = sv2v_tmp_69D9F;
	wire [1:1] sv2v_tmp_D0FD0;
	assign sv2v_tmp_D0FD0 = nanoLatch[NANO_DBIN2ABD];
	always @(*) Nanod[8] = sv2v_tmp_D0FD0;
	wire [1:1] sv2v_tmp_039CA;
	assign sv2v_tmp_039CA = nanoLatch[NANO_DBIN2DBD];
	always @(*) Nanod[7] = sv2v_tmp_039CA;
	wire [1:1] sv2v_tmp_1712D;
	assign sv2v_tmp_1712D = |aobCtrl;
	always @(*) Nanod[104] = sv2v_tmp_1712D;
	wire [1:1] sv2v_tmp_C45EE;
	assign sv2v_tmp_C45EE = |dobCtrl;
	always @(*) Nanod[102] = sv2v_tmp_C45EE;
	wire [1:1] sv2v_tmp_C294B;
	assign sv2v_tmp_C294B = (nanoLatch[NANO_TOIRC] | nanoLatch[NANO_TODBIN]) | Nanod[102];
	always @(*) Nanod[103] = sv2v_tmp_C294B;
	wire [1:1] sv2v_tmp_FF015;
	assign sv2v_tmp_FF015 = nanoLatch[NANO_BUSBYTE];
	always @(*) Nanod[101] = sv2v_tmp_FF015;
	wire [1:1] sv2v_tmp_213A2;
	assign sv2v_tmp_213A2 = nanoLatch[NANO_LOWBYTE];
	always @(*) Nanod[99] = sv2v_tmp_213A2;
	wire [1:1] sv2v_tmp_19F6E;
	assign sv2v_tmp_19F6E = nanoLatch[NANO_HIGHBYTE];
	always @(*) Nanod[98] = sv2v_tmp_19F6E;
	wire [1:1] sv2v_tmp_4C783;
	assign sv2v_tmp_4C783 = nanoLatch[NANO_ABL2REG];
	always @(*) Nanod[57] = sv2v_tmp_4C783;
	wire [1:1] sv2v_tmp_D06B8;
	assign sv2v_tmp_D06B8 = nanoLatch[NANO_ABH2REG];
	always @(*) Nanod[58] = sv2v_tmp_D06B8;
	wire [1:1] sv2v_tmp_B5A52;
	assign sv2v_tmp_B5A52 = nanoLatch[NANO_DBL2REG];
	always @(*) Nanod[53] = sv2v_tmp_B5A52;
	wire [1:1] sv2v_tmp_FFA61;
	assign sv2v_tmp_FFA61 = nanoLatch[NANO_DBH2REG];
	always @(*) Nanod[54] = sv2v_tmp_FFA61;
	wire [1:1] sv2v_tmp_CF423;
	assign sv2v_tmp_CF423 = nanoLatch[NANO_REG2DBL];
	always @(*) Nanod[52] = sv2v_tmp_CF423;
	wire [1:1] sv2v_tmp_62454;
	assign sv2v_tmp_62454 = nanoLatch[NANO_REG2DBH];
	always @(*) Nanod[51] = sv2v_tmp_62454;
	wire [1:1] sv2v_tmp_1D2B2;
	assign sv2v_tmp_1D2B2 = nanoLatch[NANO_REG2ABL];
	always @(*) Nanod[56] = sv2v_tmp_1D2B2;
	wire [1:1] sv2v_tmp_8B945;
	assign sv2v_tmp_8B945 = nanoLatch[NANO_REG2ABH];
	always @(*) Nanod[55] = sv2v_tmp_8B945;
	wire [1:1] sv2v_tmp_10BC5;
	assign sv2v_tmp_10BC5 = nanoLatch[NANO_SSP];
	always @(*) Nanod[50] = sv2v_tmp_10BC5;
	wire [1:1] sv2v_tmp_8D9D2;
	assign sv2v_tmp_8D9D2 = nanoLatch[NANO_RZ];
	always @(*) Nanod[29] = sv2v_tmp_8D9D2;
	wire dtldbd = 1'b0;
	wire dthdbh = 1'b0;
	wire dtlabd = 1'b0;
	wire dthabh = 1'b0;
	wire dblSpecial = Nanod[48] | dtldbd;
	wire dbhSpecial = Nanod[49] | dthdbh;
	wire ablSpecial = Nanod[47] | dtlabd;
	wire abhSpecial = Nanod[46] | dthabh;
	wire [1:1] sv2v_tmp_E99A5;
	assign sv2v_tmp_E99A5 = nanoLatch[NANO_RXL_DBL];
	always @(*) Nanod[28] = sv2v_tmp_E99A5;
	wire isPcRel = Irdecod[41] & !Nanod[29];
	wire pcRelDbl = isPcRel & !nanoLatch[NANO_RXL_DBL];
	wire pcRelDbh = isPcRel & !nanoLatch[NANO_RXH_DBH];
	wire pcRelAbl = isPcRel & nanoLatch[NANO_RXL_DBL];
	wire pcRelAbh = isPcRel & nanoLatch[NANO_RXH_DBH];
	wire [1:1] sv2v_tmp_4D805;
	assign sv2v_tmp_4D805 = nanoLatch[NANO_PCLDBL] | pcRelDbl;
	always @(*) Nanod[48] = sv2v_tmp_4D805;
	wire [1:1] sv2v_tmp_07CE8;
	assign sv2v_tmp_07CE8 = (nanoLatch[1:NANO_PCH] == 2'b01) | pcRelDbh;
	always @(*) Nanod[49] = sv2v_tmp_07CE8;
	wire [1:1] sv2v_tmp_A385A;
	assign sv2v_tmp_A385A = nanoLatch[NANO_PCLABL] | pcRelAbl;
	always @(*) Nanod[47] = sv2v_tmp_A385A;
	wire [1:1] sv2v_tmp_3D902;
	assign sv2v_tmp_3D902 = (nanoLatch[1:NANO_PCH] == 2'b10) | pcRelAbh;
	always @(*) Nanod[46] = sv2v_tmp_3D902;
	always @(posedge Clks[4]) begin
		if (enT4) begin
			Nanod[41] <= (Nanod[52] & !dblSpecial) & nanoLatch[NANO_RXL_DBL];
			Nanod[40] <= (Nanod[56] & !ablSpecial) & !nanoLatch[NANO_RXL_DBL];
			Nanod[43] <= (Nanod[53] & !dblSpecial) & nanoLatch[NANO_RXL_DBL];
			Nanod[39] <= (Nanod[57] & !ablSpecial) & !nanoLatch[NANO_RXL_DBL];
			Nanod[45] <= (Nanod[51] & !dbhSpecial) & nanoLatch[NANO_RXH_DBH];
			Nanod[44] <= (Nanod[55] & !abhSpecial) & !nanoLatch[NANO_RXH_DBH];
			Nanod[42] <= (Nanod[54] & !dbhSpecial) & nanoLatch[NANO_RXH_DBH];
			Nanod[38] <= (Nanod[58] & !abhSpecial) & !nanoLatch[NANO_RXH_DBH];
			Nanod[37] <= (Nanod[54] & !dbhSpecial) & !nanoLatch[NANO_RXH_DBH];
			Nanod[36] <= (Nanod[58] & !abhSpecial) & nanoLatch[NANO_RXH_DBH];
			Nanod[31] <= (Nanod[53] & !dblSpecial) & !nanoLatch[NANO_RXL_DBL];
			Nanod[30] <= (Nanod[57] & !ablSpecial) & nanoLatch[NANO_RXL_DBL];
			Nanod[35] <= (Nanod[52] & !dblSpecial) & !nanoLatch[NANO_RXL_DBL];
			Nanod[34] <= (Nanod[56] & !ablSpecial) & nanoLatch[NANO_RXL_DBL];
			Nanod[33] <= (Nanod[51] & !dbhSpecial) & !nanoLatch[NANO_RXH_DBH];
			Nanod[32] <= (Nanod[55] & !abhSpecial) & nanoLatch[NANO_RXH_DBH];
		end
		if (enT4)
			Nanod[100] <= Irdecod[40] & nanoLatch[NANO_BUSBYTE];
	end
endmodule
module irdDecode (
	ird,
	Irdecod
);
	reg _sv2v_0;
	input [15:0] ird;
	output reg [41:0] Irdecod;
	wire [3:0] line = ird[15:12];
	wire [15:0] lineOnehot;
	onehotEncoder4 irdLines(
		.bin(line),
		.bitMap(lineOnehot)
	);
	wire isRegShift = lineOnehot['he] & (ird[7:6] != 2'b11);
	wire isDynShift = isRegShift & ird[5];
	wire [1:1] sv2v_tmp_9D785;
	assign sv2v_tmp_9D785 = ((&ird[5:3] & ~isDynShift) & !ird[2]) & ird[1];
	always @(*) Irdecod[41] = sv2v_tmp_9D785;
	wire [1:1] sv2v_tmp_1BD44;
	assign sv2v_tmp_1BD44 = lineOnehot[4] & (ird[11:6] == 6'b101011);
	always @(*) Irdecod[40] = sv2v_tmp_1BD44;
	wire [3:1] sv2v_tmp_C005B;
	assign sv2v_tmp_C005B = ird[11:9];
	always @(*) Irdecod[30-:3] = sv2v_tmp_C005B;
	wire [3:1] sv2v_tmp_603B5;
	assign sv2v_tmp_603B5 = ird[2:0];
	always @(*) Irdecod[27-:3] = sv2v_tmp_603B5;
	wire isPreDecr = ird[5:3] == 3'b100;
	wire eaAreg = ird[5:3] == 3'b001;
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (1'b1)
			lineOnehot[1], lineOnehot[2], lineOnehot[3]: Irdecod[24] = |ird[8:6];
			lineOnehot[4]: Irdecod[24] = &ird[8:6];
			lineOnehot['h8]: Irdecod[24] = (eaAreg & ird[8]) & ~ird[7];
			lineOnehot['hc]: Irdecod[24] = (eaAreg & ird[8]) & ~ird[7];
			lineOnehot['h9], lineOnehot['hb], lineOnehot['hd]: Irdecod[24] = (ird[7] & ird[6]) | ((eaAreg & ird[8]) & (ird[7:6] != 2'b11));
			default: Irdecod[24] = Irdecod[39];
		endcase
	end
	always @(*) begin
		if (_sv2v_0)
			;
		Irdecod[34] = (lineOnehot[4] & ~ird[8]) & ~Irdecod[39];
	end
	wire [1:1] sv2v_tmp_2D301;
	assign sv2v_tmp_2D301 = Irdecod[34] & isPreDecr;
	always @(*) Irdecod[33] = sv2v_tmp_2D301;
	wire [1:1] sv2v_tmp_40C9E;
	assign sv2v_tmp_40C9E = lineOnehot[5] | (lineOnehot[0] & ~ird[8]);
	always @(*) Irdecod[37] = sv2v_tmp_40C9E;
	wire [1:1] sv2v_tmp_26777;
	assign sv2v_tmp_26777 = lineOnehot[4] & (ird[11:4] == 8'he6);
	always @(*) Irdecod[35] = sv2v_tmp_26777;
	wire eaImmOrAbs = (ird[5:3] == 3'b111) & ~ird[1];
	wire [1:1] sv2v_tmp_E109D;
	assign sv2v_tmp_E109D = eaImmOrAbs & ~isRegShift;
	always @(*) Irdecod[36] = sv2v_tmp_E109D;
	always @(*) begin : sv2v_autoblock_1
		reg eaIsAreg;
		if (_sv2v_0)
			;
		eaIsAreg = (ird[5:3] != 3'b000) & (ird[5:3] != 3'b111);
		(* full_case, parallel_case *)
		case (1'b1)
			default: Irdecod[23] = eaIsAreg;
			lineOnehot[5]: Irdecod[23] = eaIsAreg & (ird[7:3] != 5'b11001);
			lineOnehot[6], lineOnehot[7]: Irdecod[23] = 1'b0;
			lineOnehot['he]: Irdecod[23] = ~isRegShift;
		endcase
	end
	wire xIsScc = (ird[7:6] == 2'b11) & (ird[5:3] != 3'b001);
	wire xStaticMem = (ird[11:8] == 4'b1000) & (ird[5:4] == 2'b00);
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (1'b1)
			lineOnehot[0]: Irdecod[32] = (((ird[8] & (ird[5:4] != 2'b00)) | ((ird[11:8] == 4'b1000) & (ird[5:4] != 2'b00))) | ((ird[8:7] == 2'b10) & (ird[5:3] == 3'b001))) | ((ird[8:6] == 3'b000) & !xStaticMem);
			lineOnehot[1]: Irdecod[32] = 1'b1;
			lineOnehot[4]: Irdecod[32] = (ird[7:6] == 2'b00) | Irdecod[40];
			lineOnehot[5]: Irdecod[32] = (ird[7:6] == 2'b00) | xIsScc;
			lineOnehot[8], lineOnehot[9], lineOnehot['hb], lineOnehot['hc], lineOnehot['hd], lineOnehot['he]: Irdecod[32] = ird[7:6] == 2'b00;
			default: Irdecod[32] = 1'b0;
		endcase
	end
	wire [1:1] sv2v_tmp_4419B;
	assign sv2v_tmp_4419B = (lineOnehot[0] & ird[8]) & eaAreg;
	always @(*) Irdecod[31] = sv2v_tmp_4419B;
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (1'b1)
			lineOnehot[6]: Irdecod[39] = ird[11:8] == 4'b0001;
			lineOnehot[4]: Irdecod[39] = (ird[11:8] == 4'b1110) | (ird[11:6] == 6'b100001);
			default: Irdecod[39] = 1'b0;
		endcase
	end
	wire [1:1] sv2v_tmp_03DA9;
	assign sv2v_tmp_03DA9 = (lineOnehot[4] & ((ird[11:0] == 12'he77) | (ird[11:6] == 6'b010011))) | (lineOnehot[0] & (ird[8:6] == 3'b000));
	always @(*) Irdecod[38] = sv2v_tmp_03DA9;
	reg [15:0] ftuConst;
	wire [3:0] zero28 = (ird[11:9] == 0 ? 4'h8 : {1'b0, ird[11:9]});
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (1'b1)
			lineOnehot[6], lineOnehot[7]: ftuConst = {{8 {ird[7]}}, ird[7:0]};
			lineOnehot['h5], lineOnehot['he]: ftuConst = {12'b000000000000, zero28};
			lineOnehot['h8], lineOnehot['hc]: ftuConst = 16'h000f;
			lineOnehot[4]: ftuConst = 16'h0080;
			default: ftuConst = 1'sb0;
		endcase
	end
	wire [16:1] sv2v_tmp_D48F4;
	assign sv2v_tmp_D48F4 = ftuConst;
	always @(*) Irdecod[22-:16] = sv2v_tmp_D48F4;
	always @(*) begin
		if (_sv2v_0)
			;
		if (lineOnehot[4])
			case (ird[6:5])
				2'b00, 2'b01: Irdecod[6-:6] = 6;
				2'b11: Irdecod[6-:6] = 7;
				2'b10: Irdecod[6-:6] = {2'b10, ird[3:0]};
			endcase
		else
			Irdecod[6-:6] = 5;
	end
	wire eaAdir = ird[5:3] == 3'b001;
	wire size11 = ird[7] & ird[6];
	wire [1:1] sv2v_tmp_04E16;
	assign sv2v_tmp_04E16 = (((lineOnehot[9] | lineOnehot['hd]) & size11) | (lineOnehot[5] & eaAdir)) | ((lineOnehot[2] | lineOnehot[3]) & (ird[8:6] == 3'b001));
	always @(*) Irdecod[0] = sv2v_tmp_04E16;
	initial _sv2v_0 = 0;
endmodule
module excUnit (
	Clks,
	enT1,
	enT2,
	enT3,
	enT4,
	Nanod,
	Irdecod,
	Ird,
	pswS,
	ftu,
	iEdb,
	ccr,
	alue,
	prenEmpty,
	au05z,
	dcr4,
	ze,
	aob0,
	AblOut,
	Irc,
	oEdb,
	eab
);
	reg _sv2v_0;
	input wire [4:0] Clks;
	input enT1;
	input enT2;
	input enT3;
	input enT4;
	input wire [104:0] Nanod;
	input wire [41:0] Irdecod;
	input [15:0] Ird;
	input pswS;
	input [15:0] ftu;
	input [15:0] iEdb;
	output wire [7:0] ccr;
	output wire [15:0] alue;
	output wire prenEmpty;
	output wire au05z;
	output reg dcr4;
	output wire ze;
	output wire aob0;
	output wire [15:0] AblOut;
	output wire [15:0] Irc;
	output wire [15:0] oEdb;
	output wire [23:1] eab;
	localparam REG_USP = 15;
	localparam REG_SSP = 16;
	localparam REG_DT = 17;
	reg [15:0] regs68L [0:17];
	reg [15:0] regs68H [0:17];
	initial begin : sv2v_autoblock_1
		reg signed [31:0] i;
		for (i = 0; i < 18; i = i + 1)
			begin
				regs68L[i] <= 1'sb0;
				regs68H[i] <= 1'sb0;
			end
	end
	wire [31:0] SSP = {regs68H[REG_SSP], regs68L[REG_SSP]};
	wire [15:0] aluOut;
	wire [15:0] dbin;
	reg [15:0] dcrOutput;
	reg [15:0] PcL;
	reg [15:0] PcH;
	reg [31:0] auReg;
	reg [31:0] aob;
	reg [15:0] Ath;
	reg [15:0] Atl;
	reg [15:0] Dbl;
	reg [15:0] Dbh;
	reg [15:0] Abh;
	reg [15:0] Abl;
	reg [15:0] Abd;
	reg [15:0] Dbd;
	assign AblOut = Abl;
	assign au05z = ~|auReg[5:0];
	reg [15:0] dblMux;
	reg [15:0] dbhMux;
	reg [15:0] abhMux;
	reg [15:0] ablMux;
	reg [15:0] abdMux;
	reg [15:0] dbdMux;
	reg abdIsByte;
	reg Pcl2Dbl;
	reg Pch2Dbh;
	reg Pcl2Abl;
	reg Pch2Abh;
	reg [4:0] actualRx;
	reg [4:0] actualRy;
	reg [3:0] movemRx;
	reg byteNotSpAlign;
	reg [4:0] rxMux;
	reg [4:0] ryMux;
	reg [3:0] rxReg;
	reg [3:0] ryReg;
	reg rxIsSp;
	reg ryIsSp;
	reg rxIsAreg;
	reg ryIsAreg;
	always @(*) begin
		if (_sv2v_0)
			;
		if (Nanod[50]) begin
			rxMux = REG_SSP;
			rxIsSp = 1'b1;
			rxReg = 1'bx;
		end
		else if (Irdecod[35]) begin
			rxMux = REG_USP;
			rxIsSp = 1'b1;
			rxReg = 1'bx;
		end
		else if (Irdecod[37] & !Irdecod[39]) begin
			rxMux = REG_DT;
			rxIsSp = 1'b0;
			rxReg = 1'bx;
		end
		else begin
			if (Irdecod[39])
				rxReg = 15;
			else if (Irdecod[34])
				rxReg = movemRx;
			else
				rxReg = {Irdecod[24], Irdecod[30-:3]};
			if (&rxReg) begin
				rxMux = (pswS ? REG_SSP : 15);
				rxIsSp = 1'b1;
			end
			else begin
				rxMux = {1'b0, rxReg};
				rxIsSp = 1'b0;
			end
		end
		if (Irdecod[36] & !Nanod[29]) begin
			ryMux = REG_DT;
			ryIsSp = 1'b0;
			ryReg = 1'sbx;
		end
		else begin
			ryReg = (Nanod[29] ? Irc[15:12] : {Irdecod[23], Irdecod[27-:3]});
			ryIsSp = &ryReg;
			if (ryIsSp & pswS)
				ryMux = REG_SSP;
			else
				ryMux = {1'b0, ryReg};
		end
	end
	always @(posedge Clks[4]) begin
		if (enT4) begin
			byteNotSpAlign <= Irdecod[32] & ~(Nanod[28] ? rxIsSp : ryIsSp);
			actualRx <= rxMux;
			actualRy <= ryMux;
			rxIsAreg <= rxIsSp | rxMux[3];
			ryIsAreg <= ryIsSp | ryMux[3];
		end
		if (enT4)
			abdIsByte <= Nanod[0] & Irdecod[32];
	end
	wire ryl2Abl = Nanod[34] & (ryIsAreg | Nanod[4]);
	wire ryl2Abd = Nanod[34] & (~ryIsAreg | Nanod[4]);
	wire ryl2Dbl = Nanod[35] & (ryIsAreg | Nanod[2]);
	wire ryl2Dbd = Nanod[35] & (~ryIsAreg | Nanod[2]);
	wire rxl2Abl = Nanod[40] & (rxIsAreg | Nanod[4]);
	wire rxl2Abd = Nanod[40] & (~rxIsAreg | Nanod[4]);
	wire rxl2Dbl = Nanod[41] & (rxIsAreg | Nanod[2]);
	wire rxl2Dbd = Nanod[41] & (~rxIsAreg | Nanod[2]);
	reg abhIdle;
	reg ablIdle;
	reg abdIdle;
	reg dbhIdle;
	reg dblIdle;
	reg dbdIdle;
	always @(*) begin
		if (_sv2v_0)
			;
		{abhIdle, ablIdle, abdIdle} = 1'sb0;
		{dbhIdle, dblIdle, dbdIdle} = 1'sb0;
		(* full_case, parallel_case *)
		case (1'b1)
			ryl2Dbd: dbdMux = regs68L[actualRy];
			rxl2Dbd: dbdMux = regs68L[actualRx];
			Nanod[16]: dbdMux = alue;
			Nanod[7]: dbdMux = dbin;
			Nanod[13]: dbdMux = aluOut;
			Nanod[18]: dbdMux = dcrOutput;
			default: begin
				dbdMux = 1'sbx;
				dbdIdle = 1'b1;
			end
		endcase
		(* full_case, parallel_case *)
		case (1'b1)
			rxl2Dbl: dblMux = regs68L[actualRx];
			ryl2Dbl: dblMux = regs68L[actualRy];
			Nanod[93]: dblMux = ftu;
			Nanod[11]: dblMux = auReg[15:0];
			Nanod[70]: dblMux = Atl;
			Pcl2Dbl: dblMux = PcL;
			default: begin
				dblMux = 1'sbx;
				dblIdle = 1'b1;
			end
		endcase
		(* full_case, parallel_case *)
		case (1'b1)
			Nanod[45]: dbhMux = regs68H[actualRx];
			Nanod[33]: dbhMux = regs68H[actualRy];
			Nanod[11]: dbhMux = auReg[31:16];
			Nanod[67]: dbhMux = Ath;
			Pch2Dbh: dbhMux = PcH;
			default: begin
				dbhMux = 1'sbx;
				dbhIdle = 1'b1;
			end
		endcase
		(* full_case, parallel_case *)
		case (1'b1)
			ryl2Abd: abdMux = regs68L[actualRy];
			rxl2Abd: abdMux = regs68L[actualRx];
			Nanod[8]: abdMux = dbin;
			Nanod[12]: abdMux = aluOut;
			default: begin
				abdMux = 1'sbx;
				abdIdle = 1'b1;
			end
		endcase
		(* full_case, parallel_case *)
		case (1'b1)
			Pcl2Abl: ablMux = PcL;
			rxl2Abl: ablMux = regs68L[actualRx];
			ryl2Abl: ablMux = regs68L[actualRy];
			Nanod[92]: ablMux = ftu;
			Nanod[10]: ablMux = auReg[15:0];
			Nanod[62]: ablMux = aob[15:0];
			Nanod[71]: ablMux = Atl;
			default: begin
				ablMux = 1'sbx;
				ablIdle = 1'b1;
			end
		endcase
		(* full_case, parallel_case *)
		case (1'b1)
			Pch2Abh: abhMux = PcH;
			Nanod[44]: abhMux = regs68H[actualRx];
			Nanod[32]: abhMux = regs68H[actualRy];
			Nanod[10]: abhMux = auReg[31:16];
			Nanod[62]: abhMux = aob[31:16];
			Nanod[66]: abhMux = Ath;
			default: begin
				abhMux = 1'sbx;
				abhIdle = 1'b1;
			end
		endcase
	end
	reg [15:0] preAbh;
	reg [15:0] preAbl;
	reg [15:0] preAbd;
	reg [15:0] preDbh;
	reg [15:0] preDbl;
	reg [15:0] preDbd;
	always @(posedge Clks[4]) begin
		if (enT1) begin
			{preAbh, preAbl, preAbd} <= {abhMux, ablMux, abdMux};
			{preDbh, preDbl, preDbd} <= {dbhMux, dblMux, dbdMux};
		end
		if (enT2) begin
			if (Nanod[5])
				Abh <= {16 {(ablIdle ? preAbd[15] : preAbl[15])}};
			else if (abhIdle)
				Abh <= (ablIdle ? preAbd : preAbl);
			else
				Abh <= preAbh;
			if (~ablIdle)
				Abl <= preAbl;
			else
				Abl <= (Nanod[3] ? preAbh : preAbd);
			Abd <= (~abdIdle ? preAbd : (ablIdle ? preAbh : preAbl));
			if (Nanod[6])
				Dbh <= {16 {(dblIdle ? preDbd[15] : preDbl[15])}};
			else if (dbhIdle)
				Dbh <= (dblIdle ? preDbd : preDbl);
			else
				Dbh <= preDbh;
			if (~dblIdle)
				Dbl <= preDbl;
			else
				Dbl <= (Nanod[1] ? preDbh : preDbd);
			Dbd <= (~dbdIdle ? preDbd : (dblIdle ? preDbh : preDbl));
		end
	end
	wire au2Aob = Nanod[63] | (Nanod[11] & Nanod[65]);
	always @(posedge Clks[4])
		if (enT1 & au2Aob)
			aob <= auReg;
		else if (enT2) begin
			if (Nanod[65])
				aob <= {preDbh, (~dblIdle ? preDbl : preDbd)};
			else if (Nanod[64])
				aob <= {preAbh, (~ablIdle ? preAbl : preAbd)};
		end
	assign eab = aob[23:1];
	assign aob0 = aob[0];
	reg [31:0] auInpMux;
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (Nanod[78-:3])
			3'b000: auInpMux = 0;
			3'b001: auInpMux = (byteNotSpAlign | Nanod[79] ? 1 : 2);
			3'b010: auInpMux = -4;
			3'b011: auInpMux = {Abh, Abl};
			3'b100: auInpMux = 2;
			3'b101: auInpMux = 4;
			3'b110: auInpMux = -2;
			3'b111: auInpMux = (byteNotSpAlign | Nanod[79] ? -1 : -2);
			default: auInpMux = 1'sbx;
		endcase
	end
	wire [16:0] aulow = Dbl + auInpMux[15:0];
	wire [31:0] auResult = {(Dbh + auInpMux[31:16]) + aulow[16], aulow[15:0]};
	always @(posedge Clks[4])
		if (Clks[2])
			auReg <= 1'sb0;
		else if (enT3 & Nanod[80])
			auReg <= auResult;
	always @(posedge Clks[4])
		if (enT3) begin
			if (Nanod[43] | Nanod[39]) begin
				if (~rxIsAreg) begin
					if (Nanod[43])
						regs68L[actualRx] <= Dbd;
					else if (abdIsByte)
						regs68L[actualRx][7:0] <= Abd[7:0];
					else
						regs68L[actualRx] <= Abd;
				end
				else
					regs68L[actualRx] <= (Nanod[43] ? Dbl : Abl);
			end
			if (Nanod[31] | Nanod[30]) begin
				if (~ryIsAreg) begin
					if (Nanod[31])
						regs68L[actualRy] <= Dbd;
					else if (abdIsByte)
						regs68L[actualRy][7:0] <= Abd[7:0];
					else
						regs68L[actualRy] <= Abd;
				end
				else
					regs68L[actualRy] <= (Nanod[31] ? Dbl : Abl);
			end
			if (Nanod[42] | Nanod[38])
				regs68H[actualRx] <= (Nanod[42] ? Dbh : Abh);
			if (Nanod[37] | Nanod[36])
				regs68H[actualRy] <= (Nanod[37] ? Dbh : Abh);
		end
	reg dbl2Pcl;
	reg dbh2Pch;
	reg abh2Pch;
	reg abl2Pcl;
	always @(posedge Clks[4]) begin
		if (Clks[3]) begin
			{dbl2Pcl, dbh2Pch, abh2Pch, abl2Pcl} <= 1'sb0;
			Pcl2Dbl <= 1'b0;
			Pch2Dbh <= 1'b0;
			Pcl2Abl <= 1'b0;
			Pch2Abh <= 1'b0;
		end
		else if (enT4) begin
			dbl2Pcl <= Nanod[53] & Nanod[48];
			dbh2Pch <= Nanod[54] & Nanod[49];
			abh2Pch <= Nanod[58] & Nanod[46];
			abl2Pcl <= Nanod[57] & Nanod[47];
			Pcl2Dbl <= Nanod[52] & Nanod[48];
			Pch2Dbh <= Nanod[51] & Nanod[49];
			Pcl2Abl <= Nanod[56] & Nanod[47];
			Pch2Abh <= Nanod[55] & Nanod[46];
		end
		if (enT1 & Nanod[9])
			PcL <= auReg[15:0];
		else if (enT3) begin
			if (dbl2Pcl)
				PcL <= Dbl;
			else if (abl2Pcl)
				PcL <= Abl;
		end
		if (enT1 & Nanod[9])
			PcH <= auReg[31:16];
		else if (enT3) begin
			if (dbh2Pch)
				PcH <= Dbh;
			else if (abh2Pch)
				PcH <= Abh;
		end
		if (enT3) begin
			if (Nanod[73])
				Atl <= Dbl;
			else if (Nanod[72])
				Atl <= Abl;
		end
		if (enT3) begin
			if (Nanod[69])
				Ath <= Abh;
			else if (Nanod[68])
				Ath <= Dbh;
		end
	end
	wire rmIdle;
	wire [3:0] prHbit;
	reg [15:0] prenLatch;
	assign prenEmpty = ~|prenLatch;
	pren rmPren(
		.mask(prenLatch),
		.hbit(prHbit)
	);
	always @(posedge Clks[4])
		if (enT1 & Nanod[91])
			prenLatch <= dbin;
		else if (enT3 & Nanod[90]) begin
			prenLatch[prHbit] <= 1'b0;
			movemRx <= (Irdecod[33] ? ~prHbit : prHbit);
		end
	wire [15:0] dcrCode;
	wire [3:0] dcrInput = (abdIsByte ? {1'b0, Abd[2:0]} : Abd[3:0]);
	onehotEncoder4 dcrDecoder(
		.bin(dcrInput),
		.bitMap(dcrCode)
	);
	always @(posedge Clks[4])
		if (Clks[2])
			dcr4 <= 1'sb0;
		else if (enT3 & Nanod[19]) begin
			dcrOutput <= dcrCode;
			dcr4 <= Abd[4];
		end
	reg [15:0] alub;
	always @(posedge Clks[4])
		if (enT3) begin
			if (Nanod[15])
				alub <= Dbd;
			else if (Nanod[14])
				alub <= Abd;
		end
	wire alueClkEn = enT3 & Nanod[17];
	reg [15:0] dobInput;
	wire dobIdle = ~|Nanod[60-:2];
	localparam NANO_DOB_ADB = 2'b10;
	localparam NANO_DOB_ALU = 2'b11;
	localparam NANO_DOB_DBD = 2'b01;
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (Nanod[60-:2])
			NANO_DOB_ADB: dobInput = Abd;
			NANO_DOB_DBD: dobInput = Dbd;
			NANO_DOB_ALU: dobInput = aluOut;
			default: dobInput = 1'sbx;
		endcase
	end
	dataIo dataIo(
		.Clks(Clks),
		.enT1(enT1),
		.enT2(enT2),
		.enT3(enT3),
		.enT4(enT4),
		.Nanod(Nanod),
		.Irdecod(Irdecod),
		.iEdb(iEdb),
		.dobIdle(dobIdle),
		.dobInput(dobInput),
		.aob0(aob0),
		.Irc(Irc),
		.dbin(dbin),
		.oEdb(oEdb)
	);
	fx68kAlu alu(
		.clk(Clks[4]),
		.pwrUp(Clks[2]),
		.enT1(enT1),
		.enT3(enT3),
		.enT4(enT4),
		.ird(Ird),
		.aluColumn(Nanod[27-:3]),
		.aluAddrCtrl(Nanod[22]),
		.init(Nanod[21]),
		.finish(Nanod[20]),
		.aluIsByte(Irdecod[32]),
		.ftu2Ccr(Nanod[86]),
		.alub(alub),
		.ftu(ftu),
		.alueClkEn(alueClkEn),
		.alue(alue),
		.aluDataCtrl(Nanod[24-:2]),
		.iDataBus(Dbd),
		.iAddrBus(Abd),
		.ze(ze),
		.aluOut(aluOut),
		.ccr(ccr)
	);
	initial _sv2v_0 = 0;
endmodule
module dataIo (
	Clks,
	enT1,
	enT2,
	enT3,
	enT4,
	Nanod,
	Irdecod,
	iEdb,
	aob0,
	dobIdle,
	dobInput,
	Irc,
	dbin,
	oEdb
);
	input wire [4:0] Clks;
	input enT1;
	input enT2;
	input enT3;
	input enT4;
	input wire [104:0] Nanod;
	input wire [41:0] Irdecod;
	input [15:0] iEdb;
	input aob0;
	input dobIdle;
	input [15:0] dobInput;
	output reg [15:0] Irc;
	output reg [15:0] dbin;
	output wire [15:0] oEdb;
	reg [15:0] dob;
	reg xToDbin;
	reg xToIrc;
	reg dbinNoLow;
	reg dbinNoHigh;
	reg byteMux;
	reg isByte_T4;
	always @(posedge Clks[4]) begin
		if (enT4)
			isByte_T4 <= Irdecod[32];
		if (enT3) begin
			dbinNoHigh <= Nanod[98];
			dbinNoLow <= Nanod[99];
			byteMux <= (Nanod[101] & isByte_T4) & ~aob0;
		end
		if (enT1) begin
			xToDbin <= 1'b0;
			xToIrc <= 1'b0;
		end
		else if (enT3) begin
			xToDbin <= Nanod[75];
			xToIrc <= Nanod[74];
		end
		if (xToIrc & Clks[0])
			Irc <= iEdb;
		if (xToDbin & Clks[0]) begin
			if (~dbinNoLow)
				dbin[7:0] <= (byteMux ? iEdb[15:8] : iEdb[7:0]);
			if (~dbinNoHigh)
				dbin[15:8] <= (~byteMux & dbinNoLow ? iEdb[7:0] : iEdb[15:8]);
		end
	end
	reg byteCycle;
	always @(posedge Clks[4]) begin
		if (enT4)
			byteCycle <= Nanod[101] & Irdecod[32];
		if (enT3 & ~dobIdle) begin
			dob[7:0] <= (Nanod[99] ? dobInput[15:8] : dobInput[7:0]);
			dob[15:8] <= (byteCycle | Nanod[98] ? dobInput[7:0] : dobInput[15:8]);
		end
	end
	assign oEdb = dob;
endmodule
module uaddrDecode (
	opcode,
	a1,
	a2,
	a3,
	isPriv,
	isIllegal,
	isLineA,
	isLineF,
	lineBmap
);
	reg _sv2v_0;
	input [15:0] opcode;
	localparam UADDR_WIDTH = 10;
	output wire [9:0] a1;
	output wire [9:0] a2;
	output wire [9:0] a3;
	output reg isPriv;
	output wire isIllegal;
	output wire isLineA;
	output wire isLineF;
	output wire [15:0] lineBmap;
	wire [3:0] line = opcode[15:12];
	wire [3:0] eaCol;
	wire [3:0] movEa;
	onehotEncoder4 irLineDecod(
		.bin(line),
		.bitMap(lineBmap)
	);
	assign isLineA = lineBmap['ha];
	assign isLineF = lineBmap['hf];
	pla_lined pla_lined(
		.movEa(movEa),
		.col(eaCol),
		.opcode(opcode),
		.lineBmap(lineBmap),
		.palIll(isIllegal),
		.plaA1(a1),
		.plaA2(a2),
		.plaA3(a3)
	);
	function [3:0] eaDecode;
		input [5:0] eaBits;
		(* full_case, parallel_case *)
		case (eaBits[5:3])
			3'b111:
				case (eaBits[2:0])
					3'b000: eaDecode = 7;
					3'b001: eaDecode = 8;
					3'b010: eaDecode = 9;
					3'b011: eaDecode = 10;
					3'b100: eaDecode = 11;
					default: eaDecode = 12;
				endcase
			default: eaDecode = eaBits[5:3];
		endcase
	endfunction
	assign eaCol = eaDecode(opcode[5:0]);
	assign movEa = eaDecode({opcode[8:6], opcode[11:9]});
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (lineBmap)
			'h1: isPriv = (opcode & 16'hf5ff) == 16'h007c;
			'h10:
				if ((opcode & 16'hffc0) == 16'h46c0)
					isPriv = 1'b1;
				else if ((opcode & 16'hfff0) == 16'h4e60)
					isPriv = 1'b1;
				else if (((opcode == 16'h4e70) || (opcode == 16'h4e73)) || (opcode == 16'h4e72))
					isPriv = 1'b1;
				else
					isPriv = 1'b0;
			default: isPriv = 1'b0;
		endcase
	end
	initial _sv2v_0 = 0;
endmodule
module onehotEncoder4 (
	bin,
	bitMap
);
	reg _sv2v_0;
	input [3:0] bin;
	output reg [15:0] bitMap;
	always @(*) begin
		if (_sv2v_0)
			;
		case (bin)
			'b0: bitMap = 16'h0001;
			'b1: bitMap = 16'h0002;
			'b10: bitMap = 16'h0004;
			'b11: bitMap = 16'h0008;
			'b100: bitMap = 16'h0010;
			'b101: bitMap = 16'h0020;
			'b110: bitMap = 16'h0040;
			'b111: bitMap = 16'h0080;
			'b1000: bitMap = 16'h0100;
			'b1001: bitMap = 16'h0200;
			'b1010: bitMap = 16'h0400;
			'b1011: bitMap = 16'h0800;
			'b1100: bitMap = 16'h1000;
			'b1101: bitMap = 16'h2000;
			'b1110: bitMap = 16'h4000;
			'b1111: bitMap = 16'h8000;
		endcase
	end
	initial _sv2v_0 = 0;
endmodule
module pren (
	mask,
	hbit
);
	parameter size = 16;
	parameter outbits = 4;
	input [size - 1:0] mask;
	output reg [outbits - 1:0] hbit;
	always @(mask) begin : sv2v_autoblock_1
		integer i;
		hbit = 0;
		for (i = size - 1; i >= 0; i = i - 1)
			if (mask[i])
				hbit = i;
	end
endmodule
module sequencer (
	Clks,
	enT3,
	microLatch,
	A0Err,
	BerrA,
	busAddrErr,
	Spuria,
	Avia,
	Tpend,
	intPend,
	isIllegal,
	isPriv,
	excRst,
	isLineA,
	isLineF,
	psw,
	prenEmpty,
	au05z,
	dcr4,
	ze,
	i11,
	alue01,
	Ird,
	a1,
	a2,
	a3,
	tvn,
	nma
);
	reg _sv2v_0;
	input wire [4:0] Clks;
	input enT3;
	localparam UROM_WIDTH = 17;
	input [16:0] microLatch;
	input A0Err;
	input BerrA;
	input busAddrErr;
	input Spuria;
	input Avia;
	input Tpend;
	input intPend;
	input isIllegal;
	input isPriv;
	input excRst;
	input isLineA;
	input isLineF;
	input [15:0] psw;
	input prenEmpty;
	input au05z;
	input dcr4;
	input ze;
	input i11;
	input [1:0] alue01;
	input [15:0] Ird;
	localparam UADDR_WIDTH = 10;
	input [9:0] a1;
	input [9:0] a2;
	input [9:0] a3;
	output reg [3:0] tvn;
	output reg [9:0] nma;
	reg [9:0] uNma;
	reg [9:0] grp1Nma;
	reg [1:0] c0c1;
	reg a0Rst;
	wire A0Sel;
	wire inGrp0Exc;
	wire [9:0] dbNma = {microLatch[14:13], microLatch[6:5], microLatch[10:7], microLatch[12:11]};
	localparam BSER1_NMA = 'h3;
	localparam HALT1_NMA = 'h1;
	localparam RSTP0_NMA = 'h2;
	always @(*) begin
		if (_sv2v_0)
			;
		if (A0Err) begin
			if (a0Rst)
				nma = RSTP0_NMA;
			else if (inGrp0Exc)
				nma = HALT1_NMA;
			else
				nma = BSER1_NMA;
		end
		else
			nma = uNma;
	end
	always @(*) begin
		if (_sv2v_0)
			;
		if (microLatch[1])
			uNma = {microLatch[14:13], c0c1, microLatch[10:7], microLatch[12:11]};
		else
			case (microLatch[3:2])
				0: uNma = dbNma;
				1: uNma = (A0Sel ? grp1Nma : a1);
				2: uNma = a2;
				3: uNma = a3;
			endcase
	end
	wire [1:0] enl = {Ird[6], prenEmpty};
	wire [1:0] ms0 = {Ird[8], alue01[0]};
	wire [3:0] m01 = {au05z, Ird[8], alue01};
	localparam NF = 3;
	localparam ZF = 2;
	wire [1:0] nz1 = {psw[NF], psw[ZF]};
	localparam VF = 1;
	wire [1:0] nv = {psw[NF], psw[VF]};
	reg ccTest;
	wire [4:0] cbc = microLatch[6:2];
	localparam CF = 0;
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (cbc)
			'h0: c0c1 = {i11, i11};
			'h1: c0c1 = (au05z ? 2'b01 : 2'b11);
			'h11: c0c1 = (au05z ? 2'b00 : 2'b11);
			'h2: c0c1 = {1'b0, ~psw[CF]};
			'h12: c0c1 = {1'b1, ~psw[CF]};
			'h3: c0c1 = {psw[ZF], psw[ZF]};
			'h4:
				case (nz1)
					'b0: c0c1 = 2'b10;
					'b10: c0c1 = 2'b01;
					'b1, 'b11: c0c1 = 2'b11;
				endcase
			'h5: c0c1 = {psw[NF], 1'b1};
			'h15: c0c1 = {1'b1, psw[NF]};
			'h6: c0c1 = {~nz1[1] & ~nz1[0], 1'b1};
			'h7:
				case (ms0)
					'b10, 'b0: c0c1 = 2'b11;
					'b1: c0c1 = 2'b01;
					'b11: c0c1 = 2'b10;
				endcase
			'h8:
				case (m01)
					'b0, 'b1, 'b100, 'b111: c0c1 = 2'b11;
					'b10, 'b11, 'b101: c0c1 = 2'b01;
					'b110: c0c1 = 2'b10;
					default: c0c1 = 2'b00;
				endcase
			'h9: c0c1 = (ccTest ? 2'b11 : 2'b01);
			'h19: c0c1 = (ccTest ? 2'b11 : 2'b10);
			'hc: c0c1 = (dcr4 ? 2'b01 : 2'b11);
			'h1c: c0c1 = (dcr4 ? 2'b10 : 2'b11);
			'ha: c0c1 = (ze ? 2'b11 : 2'b00);
			'hb: c0c1 = (nv == 2'b00 ? 2'b00 : 2'b11);
			'hd: c0c1 = {~psw[VF], ~psw[VF]};
			'he, 'h1e:
				case (enl)
					2'b00: c0c1 = 'b10;
					2'b10: c0c1 = 'b11;
					2'b01, 2'b11: c0c1 = {1'b0, microLatch[6]};
				endcase
			default: c0c1 = 1'sbx;
		endcase
	end
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (Ird[11:8])
			'h0: ccTest = 1'b1;
			'h1: ccTest = 1'b0;
			'h2: ccTest = ~psw[CF] & ~psw[ZF];
			'h3: ccTest = psw[CF] | psw[ZF];
			'h4: ccTest = ~psw[CF];
			'h5: ccTest = psw[CF];
			'h6: ccTest = ~psw[ZF];
			'h7: ccTest = psw[ZF];
			'h8: ccTest = ~psw[VF];
			'h9: ccTest = psw[VF];
			'ha: ccTest = ~psw[NF];
			'hb: ccTest = psw[NF];
			'hc: ccTest = (psw[NF] & psw[VF]) | (~psw[NF] & ~psw[VF]);
			'hd: ccTest = (psw[NF] & ~psw[VF]) | (~psw[NF] & psw[VF]);
			'he: ccTest = ((psw[NF] & psw[VF]) & ~psw[ZF]) | ((~psw[NF] & ~psw[VF]) & ~psw[ZF]);
			'hf: ccTest = (psw[ZF] | (psw[NF] & ~psw[VF])) | (~psw[NF] & psw[VF]);
		endcase
	end
	reg rTrace;
	reg rInterrupt;
	reg rIllegal;
	reg rPriv;
	reg rLineA;
	reg rLineF;
	reg rExcRst;
	reg rExcAdrErr;
	reg rExcBusErr;
	reg rSpurious;
	reg rAutovec;
	wire grp1LatchEn;
	wire grp0LatchEn;
	assign grp1LatchEn = microLatch[0] & (microLatch[1] | !microLatch[4]);
	assign grp0LatchEn = microLatch[4] & !microLatch[1];
	assign inGrp0Exc = (rExcRst | rExcBusErr) | rExcAdrErr;
	localparam SF = 13;
	always @(posedge Clks[4]) begin
		if (grp0LatchEn & enT3) begin
			rExcRst <= excRst;
			rExcBusErr <= BerrA;
			rExcAdrErr <= busAddrErr;
			rSpurious <= Spuria;
			rAutovec <= Avia;
		end
		if (grp1LatchEn & enT3) begin
			rTrace <= Tpend;
			rInterrupt <= intPend;
			rIllegal <= (isIllegal & ~isLineA) & ~isLineF;
			rLineA <= isLineA;
			rLineF <= isLineF;
			rPriv <= isPriv & !psw[SF];
		end
	end
	localparam ITLX1_NMA = 'h1c4;
	localparam TRAC1_NMA = 'h1c0;
	localparam TVN_AUTOVEC = 13;
	localparam TVN_INTERRUPT = 15;
	localparam TVN_SPURIOUS = 12;
	always @(*) begin
		if (_sv2v_0)
			;
		grp1Nma = TRAC1_NMA;
		if (rExcRst)
			tvn = 1'sb0;
		else if (rExcBusErr | rExcAdrErr)
			tvn = {1'b1, rExcAdrErr};
		else if (rSpurious | rAutovec)
			tvn = (rSpurious ? TVN_SPURIOUS : TVN_AUTOVEC);
		else if (rTrace)
			tvn = 9;
		else if (rInterrupt) begin
			tvn = TVN_INTERRUPT;
			grp1Nma = ITLX1_NMA;
		end
		else
			(* full_case, parallel_case *)
			case (1'b1)
				rIllegal: tvn = 4;
				rPriv: tvn = 8;
				rLineA: tvn = 10;
				rLineF: tvn = 11;
				default: tvn = 1;
			endcase
	end
	assign A0Sel = ((((rIllegal | rLineF) | rLineA) | rPriv) | rTrace) | rInterrupt;
	always @(posedge Clks[4])
		if (Clks[3])
			a0Rst <= 1'b1;
		else if (enT3)
			a0Rst <= 1'b0;
	initial _sv2v_0 = 0;
endmodule
module busArbiter (
	Clks,
	BRi,
	BgackI,
	Halti,
	bgBlock,
	busAvail,
	BGn
);
	reg _sv2v_0;
	input wire [4:0] Clks;
	input BRi;
	input BgackI;
	input Halti;
	input bgBlock;
	output wire busAvail;
	output reg BGn;
	reg [31:0] dmaPhase;
	reg [31:0] next;
	always @(*) begin
		if (_sv2v_0)
			;
		case (dmaPhase)
			32'd0: next = 32'd1;
			32'd1:
				if (bgBlock)
					next = 32'd1;
				else if (~BgackI)
					next = 32'd4;
				else if (~BRi)
					next = 32'd2;
				else
					next = 32'd1;
			32'd4:
				if (~BRi & !bgBlock)
					next = 32'd6;
				else if (~BgackI & !bgBlock)
					next = 32'd4;
				else
					next = 32'd1;
			32'd2: next = 32'd3;
			32'd3: next = (~BRi & BgackI ? 32'd3 : 32'd4);
			32'd6: next = 32'd5;
			32'd5:
				case ({BgackI, BRi})
					2'b11: next = 32'd1;
					2'b10: next = 32'd3;
					2'b01: next = 32'd7;
					2'b00: next = 32'd5;
				endcase
			32'd7: next = 32'd4;
			default: next = 32'd1;
		endcase
	end
	reg granting;
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (next)
			32'd2, 32'd6, 32'd3, 32'd5: granting = 1'b1;
			default: granting = 1'b0;
		endcase
	end
	reg rGranted;
	assign busAvail = ((Halti & BRi) & BgackI) & ~rGranted;
	always @(posedge Clks[4]) begin
		if (Clks[3]) begin
			dmaPhase <= 32'd0;
			rGranted <= 1'b0;
		end
		else if (Clks[0]) begin
			dmaPhase <= next;
			rGranted <= granting;
		end
		if (Clks[3])
			BGn <= 1'b1;
		else if (Clks[1])
			BGn <= ~rGranted;
	end
	initial _sv2v_0 = 0;
endmodule
module busControl (
	Clks,
	enT1,
	enT4,
	permStart,
	permStop,
	iStop,
	aob0,
	isWrite,
	isByte,
	isRmc,
	busAvail,
	bgBlock,
	busAddrErr,
	waitBusCycle,
	busStarting,
	addrOe,
	bciWrite,
	rDtack,
	BeDebounced,
	Vpai,
	ASn,
	LDSn,
	UDSn,
	eRWn
);
	reg _sv2v_0;
	input wire [4:0] Clks;
	input enT1;
	input enT4;
	input permStart;
	input permStop;
	input iStop;
	input aob0;
	input isWrite;
	input isByte;
	input isRmc;
	input busAvail;
	output wire bgBlock;
	output wire busAddrErr;
	output wire waitBusCycle;
	output wire busStarting;
	output reg addrOe;
	output wire bciWrite;
	input rDtack;
	input BeDebounced;
	input Vpai;
	output wire ASn;
	output wire LDSn;
	output wire UDSn;
	output wire eRWn;
	reg rAS;
	reg rLDS;
	reg rUDS;
	reg rRWn;
	assign ASn = rAS;
	assign LDSn = rLDS;
	assign UDSn = rUDS;
	assign eRWn = rRWn;
	reg dataOe;
	reg bcPend;
	reg isWriteReg;
	reg bciByte;
	reg isRmcReg;
	reg wendReg;
	assign bciWrite = isWriteReg;
	reg addrOeDelay;
	reg isByteT4;
	wire canStart;
	wire busEnd;
	wire bcComplete;
	wire bcReset;
	wire isRcmReset = (bcComplete & bcReset) & isRmcReg;
	assign busAddrErr = aob0 & ~bciByte;
	wire busRetry = ~busAddrErr & 1'b0;
	reg [31:0] busPhase;
	reg [31:0] next;
	always @(posedge Clks[4])
		if (Clks[3])
			busPhase <= 32'd0;
		else if (Clks[1])
			busPhase <= next;
	always @(*) begin
		if (_sv2v_0)
			;
		case (busPhase)
			32'd0: next = 32'd1;
			32'd6: next = 32'd1;
			32'd2: next = 32'd3;
			32'd3: next = 32'd4;
			32'd4: next = (busEnd ? 32'd5 : 32'd4);
			32'd5: next = (isRcmReset ? 32'd6 : (canStart ? 32'd2 : 32'd1));
			32'd1: next = (canStart ? 32'd2 : 32'd1);
			default: next = 32'd1;
		endcase
	end
	wire rmcIdle = ((busPhase == 32'd1) & ~ASn) & isRmcReg;
	assign canStart = (((busAvail | rmcIdle) & (bcPend | permStart)) & !busRetry) & !bcReset;
	wire busEnding = (next == 32'd1) | (next == 32'd2);
	assign busStarting = busPhase == 32'd2;
	assign busEnd = ~rDtack | iStop;
	assign bcComplete = busPhase == 32'd5;
	wire bciClear = bcComplete & ~busRetry;
	assign bcReset = Clks[3] | ((addrOeDelay & BeDebounced) & Vpai);
	assign waitBusCycle = wendReg & !bcComplete;
	assign bgBlock = ((busPhase == 32'd2) & ASn) | (busPhase == 32'd6);
	always @(posedge Clks[4]) begin
		if (Clks[3])
			addrOe <= 1'b0;
		else if (Clks[0] & (busPhase == 32'd2))
			addrOe <= 1'b1;
		else if (Clks[1] & (busPhase == 32'd6))
			addrOe <= 1'b0;
		else if ((Clks[1] & ~isRmcReg) & busEnding)
			addrOe <= 1'b0;
		if (Clks[1])
			addrOeDelay <= addrOe;
		if (Clks[3]) begin
			rAS <= 1'b1;
			rUDS <= 1'b1;
			rLDS <= 1'b1;
			rRWn <= 1'b1;
			dataOe <= 1'sb0;
		end
		else begin
			if ((Clks[0] & isWriteReg) & (busPhase == 32'd3))
				dataOe <= 1'b1;
			else if (Clks[1] & (busEnding | (busPhase == 32'd1)))
				dataOe <= 1'b0;
			if (Clks[1] & busEnding)
				rRWn <= 1'b1;
			else if (Clks[1] & isWriteReg) begin
				if ((busPhase == 32'd2) & isWriteReg)
					rRWn <= 1'b0;
			end
			if (Clks[1] & (busPhase == 32'd2))
				rAS <= 1'b0;
			else if (Clks[0] & (busPhase == 32'd6))
				rAS <= 1'b1;
			else if ((Clks[0] & bcComplete) & ~32'd6) begin
				if (~isRmcReg)
					rAS <= 1'b1;
			end
			if (Clks[1] & (busPhase == 32'd2)) begin
				if (~isWriteReg & !busAddrErr) begin
					rUDS <= ~(~bciByte | ~aob0);
					rLDS <= ~(~bciByte | aob0);
				end
			end
			else if (((Clks[1] & isWriteReg) & (busPhase == 32'd3)) & !busAddrErr) begin
				rUDS <= ~(~bciByte | ~aob0);
				rLDS <= ~(~bciByte | aob0);
			end
			else if (Clks[0] & bcComplete) begin
				rUDS <= 1'b1;
				rLDS <= 1'b1;
			end
		end
	end
	always @(posedge Clks[4])
		if (enT4)
			isByteT4 <= isByte;
	always @(posedge Clks[4])
		if (Clks[2]) begin
			bcPend <= 1'b0;
			wendReg <= 1'b0;
			isWriteReg <= 1'b0;
			bciByte <= 1'b0;
			isRmcReg <= 1'b0;
		end
		else if (Clks[0] & (bciClear | bcReset)) begin
			bcPend <= 1'b0;
			wendReg <= 1'b0;
		end
		else begin
			if (enT1 & permStart) begin
				isWriteReg <= isWrite;
				bciByte <= isByteT4;
				isRmcReg <= isRmc & ~isWrite;
				bcPend <= 1'b1;
			end
			if (enT1)
				wendReg <= permStop;
		end
	initial _sv2v_0 = 0;
endmodule
module microToNanoAddr (
	uAddr,
	orgAddr
);
	localparam UADDR_WIDTH = 10;
	input [9:0] uAddr;
	localparam NADDR_WIDTH = 9;
	output wire [8:0] orgAddr;
	wire [9:2] baseAddr = uAddr[9:2];
	reg [8:2] orgBase;
	assign orgAddr = {orgBase, uAddr[1:0]};
	always @(baseAddr)
		case (baseAddr)
			'h0: orgBase = 7'h00;
			'h1: orgBase = 7'h01;
			'h2: orgBase = 7'h02;
			'h3: orgBase = 7'h02;
			'h8: orgBase = 7'h03;
			'h9: orgBase = 7'h04;
			'ha: orgBase = 7'h05;
			'hb: orgBase = 7'h05;
			'h10: orgBase = 7'h06;
			'h11: orgBase = 7'h07;
			'h12: orgBase = 7'h08;
			'h13: orgBase = 7'h08;
			'h18: orgBase = 7'h09;
			'h19: orgBase = 7'h0a;
			'h1a: orgBase = 7'h0b;
			'h1b: orgBase = 7'h0b;
			'h20: orgBase = 7'h0c;
			'h21: orgBase = 7'h0d;
			'h22: orgBase = 7'h0e;
			'h23: orgBase = 7'h0d;
			'h28: orgBase = 7'h0f;
			'h29: orgBase = 7'h10;
			'h2a: orgBase = 7'h11;
			'h2b: orgBase = 7'h10;
			'h30: orgBase = 7'h12;
			'h31: orgBase = 7'h13;
			'h32: orgBase = 7'h14;
			'h33: orgBase = 7'h14;
			'h38: orgBase = 7'h15;
			'h39: orgBase = 7'h16;
			'h3a: orgBase = 7'h17;
			'h3b: orgBase = 7'h17;
			'h40: orgBase = 7'h18;
			'h41: orgBase = 7'h18;
			'h42: orgBase = 7'h18;
			'h43: orgBase = 7'h18;
			'h44: orgBase = 7'h19;
			'h45: orgBase = 7'h19;
			'h46: orgBase = 7'h19;
			'h47: orgBase = 7'h19;
			'h48: orgBase = 7'h1a;
			'h49: orgBase = 7'h1a;
			'h4a: orgBase = 7'h1a;
			'h4b: orgBase = 7'h1a;
			'h4c: orgBase = 7'h1b;
			'h4d: orgBase = 7'h1b;
			'h4e: orgBase = 7'h1b;
			'h4f: orgBase = 7'h1b;
			'h54: orgBase = 7'h1c;
			'h55: orgBase = 7'h1d;
			'h56: orgBase = 7'h1e;
			'h57: orgBase = 7'h1f;
			'h5c: orgBase = 7'h20;
			'h5d: orgBase = 7'h21;
			'h5e: orgBase = 7'h22;
			'h5f: orgBase = 7'h23;
			'h70: orgBase = 7'h24;
			'h71: orgBase = 7'h24;
			'h72: orgBase = 7'h24;
			'h73: orgBase = 7'h24;
			'h74: orgBase = 7'h24;
			'h75: orgBase = 7'h24;
			'h76: orgBase = 7'h24;
			'h77: orgBase = 7'h24;
			'h78: orgBase = 7'h25;
			'h79: orgBase = 7'h25;
			'h7a: orgBase = 7'h25;
			'h7b: orgBase = 7'h25;
			'h7c: orgBase = 7'h25;
			'h7d: orgBase = 7'h25;
			'h7e: orgBase = 7'h25;
			'h7f: orgBase = 7'h25;
			'h84: orgBase = 7'h26;
			'h85: orgBase = 7'h27;
			'h86: orgBase = 7'h28;
			'h87: orgBase = 7'h29;
			'h8c: orgBase = 7'h2a;
			'h8d: orgBase = 7'h2b;
			'h8e: orgBase = 7'h2c;
			'h8f: orgBase = 7'h2d;
			'h94: orgBase = 7'h2e;
			'h95: orgBase = 7'h2f;
			'h96: orgBase = 7'h30;
			'h97: orgBase = 7'h31;
			'h9c: orgBase = 7'h32;
			'h9d: orgBase = 7'h33;
			'h9e: orgBase = 7'h34;
			'h9f: orgBase = 7'h35;
			'ha4: orgBase = 7'h36;
			'ha5: orgBase = 7'h36;
			'ha6: orgBase = 7'h37;
			'ha7: orgBase = 7'h37;
			'hac: orgBase = 7'h38;
			'had: orgBase = 7'h38;
			'hae: orgBase = 7'h39;
			'haf: orgBase = 7'h39;
			'hb4: orgBase = 7'h3a;
			'hb5: orgBase = 7'h3a;
			'hb6: orgBase = 7'h3b;
			'hb7: orgBase = 7'h3b;
			'hbc: orgBase = 7'h3c;
			'hbd: orgBase = 7'h3c;
			'hbe: orgBase = 7'h3d;
			'hbf: orgBase = 7'h3d;
			'hc0: orgBase = 7'h3e;
			'hc1: orgBase = 7'h3f;
			'hc2: orgBase = 7'h40;
			'hc3: orgBase = 7'h41;
			'hc8: orgBase = 7'h42;
			'hc9: orgBase = 7'h43;
			'hca: orgBase = 7'h44;
			'hcb: orgBase = 7'h45;
			'hd0: orgBase = 7'h46;
			'hd1: orgBase = 7'h47;
			'hd2: orgBase = 7'h48;
			'hd3: orgBase = 7'h49;
			'hd8: orgBase = 7'h4a;
			'hd9: orgBase = 7'h4b;
			'hda: orgBase = 7'h4c;
			'hdb: orgBase = 7'h4d;
			'he0: orgBase = 7'h4e;
			'he1: orgBase = 7'h4e;
			'he2: orgBase = 7'h4f;
			'he3: orgBase = 7'h4f;
			'he8: orgBase = 7'h50;
			'he9: orgBase = 7'h50;
			'hea: orgBase = 7'h51;
			'heb: orgBase = 7'h51;
			'hf0: orgBase = 7'h52;
			'hf1: orgBase = 7'h52;
			'hf2: orgBase = 7'h52;
			'hf3: orgBase = 7'h52;
			'hf8: orgBase = 7'h53;
			'hf9: orgBase = 7'h53;
			'hfa: orgBase = 7'h53;
			'hfb: orgBase = 7'h53;
			default: orgBase = 1'sbx;
		endcase
endmodule
module fx68kAlu (
	clk,
	pwrUp,
	enT1,
	enT3,
	enT4,
	ird,
	aluColumn,
	aluDataCtrl,
	aluAddrCtrl,
	alueClkEn,
	ftu2Ccr,
	init,
	finish,
	aluIsByte,
	ftu,
	alub,
	iDataBus,
	iAddrBus,
	ze,
	alue,
	ccr,
	aluOut
);
	reg _sv2v_0;
	input clk;
	input pwrUp;
	input enT1;
	input enT3;
	input enT4;
	input [15:0] ird;
	input [2:0] aluColumn;
	input [1:0] aluDataCtrl;
	input aluAddrCtrl;
	input alueClkEn;
	input ftu2Ccr;
	input init;
	input finish;
	input aluIsByte;
	input [15:0] ftu;
	input [15:0] alub;
	input [15:0] iDataBus;
	input [15:0] iAddrBus;
	output wire ze;
	output reg [15:0] alue;
	output reg [7:0] ccr;
	output wire [15:0] aluOut;
	localparam CF = 0;
	localparam VF = 1;
	localparam ZF = 2;
	localparam NF = 3;
	localparam XF = 4;
	reg [15:0] aluLatch;
	reg [4:0] pswCcr;
	reg [4:0] ccrCore;
	reg [15:0] result;
	reg [4:0] ccrTemp;
	reg coreH;
	reg [15:0] subResult;
	reg subHcarry;
	reg subCout;
	reg subOv;
	assign aluOut = aluLatch;
	assign ze = ~ccrCore[ZF];
	reg [15:0] row;
	reg isArX;
	reg noCcrEn;
	reg isByte;
	reg [4:0] ccrMask;
	reg [4:0] oper;
	reg [15:0] aOperand;
	reg [15:0] dOperand;
	wire isCorf = aluDataCtrl == 2'b10;
	wire [15:0] cRow;
	wire cIsArX;
	wire cNoCcrEn;
	rowDecoder rowDecoder(
		.ird(ird),
		.row(cRow),
		.noCcrEn(cNoCcrEn),
		.isArX(cIsArX)
	);
	wire [4:0] cMask;
	wire [4:0] aluOp;
	aluGetOp aluGetOp(
		.row(row),
		.col(aluColumn),
		.isCorf(isCorf),
		.aluOp(aluOp)
	);
	ccrTable ccrTable(
		.col(aluColumn),
		.row(row),
		.finish(finish),
		.ccrMask(cMask)
	);
	wire shftIsMul = row[7];
	wire shftIsDiv = row[1];
	wire [31:0] shftResult;
	reg [7:0] bcdLatch;
	reg bcdCarry;
	reg bcdOverf;
	reg isLong;
	reg rIrd8;
	reg isShift;
	reg shftCin;
	reg shftRight;
	reg addCin;
	always @(posedge clk) begin
		if (enT3) begin
			row <= cRow;
			isArX <= cIsArX;
			noCcrEn <= cNoCcrEn;
			rIrd8 <= ird[8];
			isByte <= aluIsByte;
		end
		if (enT4) begin
			isLong <= ((ird[7] & ~ird[6]) | shftIsMul) | shftIsDiv;
			ccrMask <= cMask;
			oper <= aluOp;
		end
	end
	always @(*) begin
		if (_sv2v_0)
			;
		aOperand = (aluAddrCtrl ? alub : iAddrBus);
		case (aluDataCtrl)
			2'b00: dOperand = iDataBus;
			2'b01: dOperand = 'h0;
			2'b11: dOperand = 'hffff;
			2'b10: dOperand = 1'sbx;
		endcase
	end
	wire shftMsb = (isLong ? alue[15] : (isByte ? aOperand[7] : aOperand[15]));
	aluShifter shifter(
		.data({alue, aOperand}),
		.swapWords(shftIsMul | shftIsDiv),
		.cin(shftCin),
		.dir(shftRight),
		.isByte(isByte),
		.isLong(isLong),
		.result(shftResult)
	);
	wire [7:0] bcdResult;
	wire bcdC;
	wire bcdV;
	localparam OP_SBCD = 6;
	aluCorf aluCorf(
		.binResult(aluLatch[7:0]),
		.hCarry(coreH),
		.bAdd(oper != OP_SBCD),
		.cin(pswCcr[XF]),
		.bcdResult(bcdResult),
		.dC(bcdC),
		.ov(bcdV)
	);
	always @(posedge clk)
		if (enT1) begin
			bcdLatch <= bcdResult;
			bcdCarry <= bcdC;
			bcdOverf <= bcdV;
		end
	localparam OP_ADD = 4;
	localparam OP_ADDC = 11;
	localparam OP_ADDX = 12;
	localparam OP_SUB = 2;
	localparam OP_SUB0 = 7;
	localparam OP_SUBC = 10;
	localparam OP_SUBX = 3;
	always @(*) begin
		if (_sv2v_0)
			;
		case (oper)
			OP_ADD, OP_SUB: addCin = 1'b0;
			OP_SUB0: addCin = 1'b1;
			OP_ADDC, OP_SUBC: addCin = ccrCore[CF];
			OP_ADDX, OP_SUBX: addCin = pswCcr[XF];
			default: addCin = 1'bx;
		endcase
	end
	localparam OP_ASL = 13;
	localparam OP_ASR = 14;
	localparam OP_LSL = 15;
	localparam OP_LSR = 16;
	localparam OP_ROL = 17;
	localparam OP_ROR = 18;
	localparam OP_ROXL = 19;
	localparam OP_ROXR = 20;
	localparam OP_SLAA = 21;
	always @(*) begin
		if (_sv2v_0)
			;
		case (oper)
			OP_LSL, OP_ASL, OP_ROL, OP_ROXL, OP_SLAA: shftRight = 1'b0;
			OP_LSR, OP_ASR, OP_ROR, OP_ROXR: shftRight = 1'b1;
			default: shftRight = 1'bx;
		endcase
		case (oper)
			OP_LSR, OP_ASL, OP_LSL: shftCin = 1'b0;
			OP_ROL, OP_ASR: shftCin = shftMsb;
			OP_ROR: shftCin = aOperand[0];
			OP_ROXL, OP_ROXR:
				if (shftIsMul)
					shftCin = (rIrd8 ? pswCcr[NF] ^ pswCcr[VF] : pswCcr[CF]);
				else
					shftCin = pswCcr[XF];
			OP_SLAA: shftCin = aluColumn[1];
			default: shftCin = 1'sbx;
		endcase
	end
	task mySubber;
		input [15:0] inpa;
		input [15:0] inpb;
		input cin;
		input bAdd;
		input isByte;
		output reg [15:0] result;
		output reg cout;
		output reg ov;
		reg [16:0] rtemp;
		reg rm;
		reg sm;
		reg dm;
		reg tsm;
		begin
			if (isByte) begin
				rtemp = (bAdd ? ({1'b0, inpb[7:0]} + {1'b0, inpa[7:0]}) + cin : ({1'b0, inpb[7:0]} - {1'b0, inpa[7:0]}) - cin);
				result = {{8 {rtemp[7]}}, rtemp[7:0]};
				cout = rtemp[8];
			end
			else begin
				rtemp = (bAdd ? ({1'b0, inpb} + {1'b0, inpa}) + cin : ({1'b0, inpb} - {1'b0, inpa}) - cin);
				result = rtemp[15:0];
				cout = rtemp[16];
			end
			rm = (isByte ? rtemp[7] : rtemp[15]);
			dm = (isByte ? inpb[7] : inpb[15]);
			tsm = (isByte ? inpa[7] : inpa[15]);
			sm = (bAdd ? tsm : ~tsm);
			ov = ((sm & dm) & ~rm) | ((~sm & ~dm) & rm);
			subHcarry = (inpa[4] ^ inpb[4]) ^ rtemp[4];
		end
	endtask
	localparam OP_ABCD = 22;
	localparam OP_AND = 1;
	localparam OP_EOR = 9;
	localparam OP_EXT = 5;
	localparam OP_OR = 8;
	always @(*) begin
		if (_sv2v_0)
			;
		mySubber(aOperand, dOperand, addCin, ((oper == OP_ADD) | (oper == OP_ADDC)) | (oper == OP_ADDX), isByte, subResult, subCout, subOv);
		isShift = 1'b0;
		case (oper)
			OP_AND: result = aOperand & dOperand;
			OP_OR: result = aOperand | dOperand;
			OP_EOR: result = aOperand ^ dOperand;
			OP_EXT: result = {{8 {aOperand[7]}}, aOperand[7:0]};
			OP_SLAA, OP_ASL, OP_ASR, OP_LSL, OP_LSR, OP_ROL, OP_ROR, OP_ROXL, OP_ROXR: begin
				result = shftResult[15:0];
				isShift = 1'b1;
			end
			OP_ADD, OP_ADDC, OP_ADDX, OP_SUB, OP_SUBC, OP_SUB0, OP_SUBX: result = subResult;
			OP_ABCD, OP_SBCD: result = {8'hxx, bcdLatch};
			default: result = 1'sbx;
		endcase
	end
	always @(*) begin
		if (_sv2v_0)
			;
		ccrTemp[XF] = pswCcr[XF];
		ccrTemp[CF] = 0;
		ccrTemp[VF] = 0;
		ccrTemp[ZF] = (isByte ? ~(|result[7:0]) : ~(|result));
		ccrTemp[NF] = (isByte ? result[7] : result[15]);
		(* full_case, parallel_case *)
		case (oper)
			OP_EXT:
				if (aluColumn == 5) begin
					ccrTemp[VF] = 1'b1;
					ccrTemp[NF] = 1'b1;
					ccrTemp[ZF] = 1'b0;
				end
			OP_SUB0, OP_OR, OP_EOR: begin
				ccrTemp[CF] = 0;
				ccrTemp[VF] = 0;
			end
			OP_AND: begin
				if ((aluColumn == 1) & (row[11] | row[8]))
					ccrTemp[CF] = pswCcr[XF];
				else
					ccrTemp[CF] = 0;
				ccrTemp[VF] = 0;
			end
			OP_SLAA: ccrTemp[CF] = aOperand[15];
			OP_LSL, OP_ROXL: begin
				ccrTemp[CF] = shftMsb;
				ccrTemp[XF] = shftMsb;
				ccrTemp[VF] = 1'b0;
			end
			OP_LSR, OP_ROXR: begin
				ccrTemp[CF] = (shftIsMul ? 1'b0 : aOperand[0]);
				ccrTemp[XF] = aOperand[0];
				ccrTemp[VF] = 0;
			end
			OP_ASL: begin
				ccrTemp[XF] = shftMsb;
				ccrTemp[CF] = shftMsb;
				ccrTemp[VF] = pswCcr[VF] | (shftMsb ^ (isLong ? alue[14] : (isByte ? aOperand[6] : aOperand[14])));
			end
			OP_ASR: begin
				ccrTemp[XF] = aOperand[0];
				ccrTemp[CF] = aOperand[0];
				ccrTemp[VF] = 0;
			end
			OP_ROL: ccrTemp[CF] = shftMsb;
			OP_ROR: ccrTemp[CF] = aOperand[0];
			OP_ADD, OP_ADDC, OP_ADDX, OP_SUB, OP_SUBC, OP_SUBX: begin
				ccrTemp[CF] = subCout;
				ccrTemp[XF] = subCout;
				ccrTemp[VF] = subOv;
			end
			OP_ABCD, OP_SBCD: begin
				ccrTemp[XF] = bcdCarry;
				ccrTemp[CF] = bcdCarry;
				ccrTemp[VF] = bcdOverf;
			end
		endcase
	end
	reg [4:0] ccrMasked;
	always @(*) begin
		if (_sv2v_0)
			;
		ccrMasked = (ccrTemp & ccrMask) | (pswCcr & ~ccrMask);
		if (finish | isArX)
			ccrMasked[ZF] = ccrTemp[ZF] & pswCcr[ZF];
	end
	always @(posedge clk) begin
		if (enT3) begin
			if (|aluColumn) begin
				aluLatch <= result;
				coreH <= subHcarry;
				if (|aluColumn)
					ccrCore <= ccrTemp;
			end
			if (alueClkEn)
				alue <= iDataBus;
			else if (isShift & |aluColumn)
				alue <= shftResult[31:16];
		end
		if (pwrUp)
			pswCcr <= 1'sb0;
		else if (enT3 & ftu2Ccr)
			pswCcr <= ftu[4:0];
		else if ((enT3 & ~noCcrEn) & (finish | init))
			pswCcr <= ccrMasked;
	end
	wire [8:1] sv2v_tmp_D1156;
	assign sv2v_tmp_D1156 = {3'b000, pswCcr};
	always @(*) ccr = sv2v_tmp_D1156;
	initial _sv2v_0 = 0;
endmodule
module aluCorf (
	binResult,
	bAdd,
	cin,
	hCarry,
	bcdResult,
	dC,
	ov
);
	reg _sv2v_0;
	input [7:0] binResult;
	input bAdd;
	input cin;
	input hCarry;
	output wire [7:0] bcdResult;
	output wire dC;
	output reg ov;
	reg [8:0] htemp;
	reg [4:0] hNib;
	function gt9;
		input [3:0] nib;
		gt9 = nib[3] & (nib[2] | nib[1]);
	endfunction
	wire lowC = hCarry | (bAdd ? gt9(binResult[3:0]) : 1'b0);
	wire highC = cin | (bAdd ? gt9(htemp[7:4]) | htemp[8] : 1'b0);
	always @(*) begin
		if (_sv2v_0)
			;
		if (bAdd) begin
			htemp = {1'b0, binResult} + (lowC ? 4'h6 : 4'h0);
			hNib = htemp[8:4] + (highC ? 4'h6 : 4'h0);
			ov = hNib[3] & ~binResult[7];
		end
		else begin
			htemp = {1'b0, binResult} - (lowC ? 4'h6 : 4'h0);
			hNib = htemp[8:4] - (highC ? 4'h6 : 4'h0);
			ov = ~hNib[3] & binResult[7];
		end
	end
	assign bcdResult = {hNib[3:0], htemp[3:0]};
	assign dC = hNib[4] | cin;
	initial _sv2v_0 = 0;
endmodule
module aluShifter (
	data,
	isByte,
	isLong,
	swapWords,
	dir,
	cin,
	result
);
	reg _sv2v_0;
	input [31:0] data;
	input isByte;
	input isLong;
	input swapWords;
	input dir;
	input cin;
	output reg [31:0] result;
	reg [31:0] tdata;
	always @(*) begin
		if (_sv2v_0)
			;
		tdata = data;
		if (isByte & dir)
			tdata[8] = cin;
		else if (!isLong & dir)
			tdata[16] = cin;
	end
	always @(*) begin
		if (_sv2v_0)
			;
		if (swapWords & dir)
			result = {tdata[0], tdata[31:17], cin, tdata[15:1]};
		else if (swapWords)
			result = {tdata[30:16], cin, tdata[14:0], tdata[31]};
		else if (dir)
			result = {cin, tdata[31:1]};
		else
			result = {tdata[30:0], cin};
	end
	initial _sv2v_0 = 0;
endmodule
module aluGetOp (
	row,
	col,
	isCorf,
	aluOp
);
	reg _sv2v_0;
	input [15:0] row;
	input [2:0] col;
	input isCorf;
	output reg [4:0] aluOp;
	localparam OP_ABCD = 22;
	localparam OP_ADD = 4;
	localparam OP_ADDC = 11;
	localparam OP_ADDX = 12;
	localparam OP_AND = 1;
	localparam OP_ASL = 13;
	localparam OP_ASR = 14;
	localparam OP_EOR = 9;
	localparam OP_EXT = 5;
	localparam OP_LSL = 15;
	localparam OP_LSR = 16;
	localparam OP_OR = 8;
	localparam OP_ROL = 17;
	localparam OP_ROR = 18;
	localparam OP_ROXL = 19;
	localparam OP_ROXR = 20;
	localparam OP_SBCD = 6;
	localparam OP_SLAA = 21;
	localparam OP_SUB = 2;
	localparam OP_SUB0 = 7;
	localparam OP_SUBC = 10;
	localparam OP_SUBX = 3;
	always @(*) begin
		if (_sv2v_0)
			;
		aluOp = 1'sbx;
		(* full_case, parallel_case *)
		case (col)
			1: aluOp = OP_AND;
			5: aluOp = OP_EXT;
			default:
				(* full_case, parallel_case *)
				case (1'b1)
					row[1]:
						(* full_case, parallel_case *)
						case (col)
							2: aluOp = OP_SUB;
							3: aluOp = OP_SUBC;
							4, 6: aluOp = OP_SLAA;
						endcase
					row[2]:
						(* full_case, parallel_case *)
						case (col)
							2: aluOp = OP_ADD;
							3: aluOp = OP_ADDC;
							4: aluOp = OP_ASR;
						endcase
					row[3]:
						(* full_case, parallel_case *)
						case (col)
							2: aluOp = OP_ADDX;
							3: aluOp = (isCorf ? OP_ABCD : OP_ADD);
							4: aluOp = OP_ASL;
						endcase
					row[4]: aluOp = (col == 4 ? OP_LSL : OP_AND);
					row[5], row[6]:
						(* full_case, parallel_case *)
						case (col)
							2: aluOp = OP_SUB;
							3: aluOp = OP_SUBC;
							4: aluOp = OP_LSR;
						endcase
					row[7]:
						(* full_case, parallel_case *)
						case (col)
							2: aluOp = OP_SUB;
							3: aluOp = OP_ADD;
							4: aluOp = OP_ROXR;
						endcase
					row[8]:
						(* full_case, parallel_case *)
						case (col)
							2: aluOp = OP_EXT;
							3: aluOp = OP_AND;
							4: aluOp = OP_ROXR;
						endcase
					row[9]:
						(* full_case, parallel_case *)
						case (col)
							2: aluOp = OP_SUBX;
							3: aluOp = OP_SBCD;
							4: aluOp = OP_ROL;
						endcase
					row[10]:
						(* full_case, parallel_case *)
						case (col)
							2: aluOp = OP_SUBX;
							3: aluOp = OP_SUBC;
							4: aluOp = OP_ROR;
						endcase
					row[11]:
						(* full_case, parallel_case *)
						case (col)
							2: aluOp = OP_SUB0;
							3: aluOp = OP_SUB0;
							4: aluOp = OP_ROXL;
						endcase
					row[12]: aluOp = OP_ADDX;
					row[13]: aluOp = OP_EOR;
					row[14]: aluOp = (col == 4 ? OP_EOR : OP_OR);
					row[15]: aluOp = (col == 3 ? OP_ADD : OP_OR);
				endcase
		endcase
	end
	initial _sv2v_0 = 0;
endmodule
module rowDecoder (
	ird,
	row,
	noCcrEn,
	isArX
);
	reg _sv2v_0;
	input [15:0] ird;
	output reg [15:0] row;
	output wire noCcrEn;
	output reg isArX;
	wire eaRdir = ird[5:4] == 2'b00;
	wire eaAdir = ird[5:3] == 3'b001;
	wire size11 = ird[7] & ird[6];
	always @(*) begin
		if (_sv2v_0)
			;
		case (ird[15:12])
			'h4, 'h9, 'hd: isArX = row[10] | row[12];
			default: isArX = 1'b0;
		endcase
	end
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (ird[15:12])
			'h4:
				if (ird[8])
					row = 16'h0040;
				else
					case (ird[11:9])
						'b0: row = 16'h0400;
						'b1: row = 16'h0010;
						'b10: row = 16'h0020;
						'b11: row = 16'h0800;
						'b100: row = (ird[7] ? 16'h0100 : 16'h0200);
						'b101: row = 16'h8000;
						default: row = 0;
					endcase
			'h0:
				if (ird[8])
					row = (ird[7] ? 16'h4000 : 16'h2000);
				else
					case (ird[11:9])
						'b0: row = 16'h4000;
						'b1: row = 16'h0010;
						'b10: row = 16'h0020;
						'b11: row = 16'h0004;
						'b100: row = (ird[7] ? 16'h4000 : 16'h2000);
						'b101: row = 16'h2000;
						'b110: row = 16'h0040;
						default: row = 0;
					endcase
			'h1, 'h2, 'h3: row = 16'h0004;
			'h5:
				if (size11)
					row = 16'h8000;
				else
					row = (ird[8] ? 16'h0020 : 16'h0004);
			'h6: row = 0;
			'h7: row = 16'h0004;
			'h8:
				if (size11)
					row = 16'h0002;
				else if (ird[8] & eaRdir)
					row = 16'h0200;
				else
					row = 16'h4000;
			'h9:
				if ((ird[8] & ~size11) & eaRdir)
					row = 16'h0400;
				else
					row = 16'h0020;
			'hb:
				if ((ird[8] & ~size11) & ~eaAdir)
					row = 16'h2000;
				else
					row = 16'h0040;
			'hc:
				if (size11)
					row = 16'h0080;
				else if (ird[8] & eaRdir)
					row = 16'h0008;
				else
					row = 16'h0010;
			'hd:
				if ((ird[8] & ~size11) & eaRdir)
					row = 16'h1000;
				else
					row = 16'h0004;
			'he:
				case ({(size11 ? ird[10:9] : ird[4:3]), ird[8]})
					0: row = 16'h0004;
					1: row = 16'h0008;
					2: row = 16'h0020;
					3: row = 16'h0010;
					4: row = 16'h0100;
					5: row = 16'h0800;
					6: row = 16'h0400;
					7: row = 16'h0200;
				endcase
			default: row = 0;
		endcase
	end
	assign noCcrEn = ((((ird[15] & ~ird[13]) & ird[12]) & size11) | ((ird[15:12] == 4'h5) & eaAdir)) | (((~ird[15] & ~ird[14]) & ird[13]) & (ird[8:6] == 3'b001));
	initial _sv2v_0 = 0;
endmodule
module ccrTable (
	col,
	row,
	finish,
	ccrMask
);
	reg _sv2v_0;
	input [2:0] col;
	input [15:0] row;
	input finish;
	localparam MASK_NBITS = 5;
	output reg [4:0] ccrMask;
	localparam KNZ00 = 5'b01111;
	localparam KKZKK = 5'b00100;
	localparam KNZKK = 5'b01100;
	localparam KNZ10 = 5'b01111;
	localparam KNZ0C = 5'b01111;
	localparam KNZVC = 5'b01111;
	localparam XNKVC = 5'b11011;
	localparam CUPDALL = 5'b11111;
	localparam CUNUSED = 5'bxxxxx;
	reg [4:0] ccrMask1;
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (col)
			1: ccrMask = ccrMask1;
			2, 3:
				(* full_case, parallel_case *)
				case (1'b1)
					row[1]: ccrMask = KNZ0C;
					row[3], row[9]: ccrMask = (col == 2 ? XNKVC : CUPDALL);
					row[2], row[5], row[10], row[12]: ccrMask = CUPDALL;
					row[6], row[7], row[11]: ccrMask = KNZVC;
					row[4], row[8], row[13], row[14]: ccrMask = KNZ00;
					row[15]: ccrMask = 5'b00000;
				endcase
			4:
				(* full_case, parallel_case *)
				case (row)
					16'h0004, 16'h0008, 16'h0010, 16'h0020: ccrMask = CUPDALL;
					16'h0080: ccrMask = KNZ00;
					16'h0200, 16'h0400: ccrMask = KNZ00;
					16'h0100, 16'h0800: ccrMask = CUPDALL;
					default: ccrMask = CUNUSED;
				endcase
			5: ccrMask = (row[1] ? KNZ10 : 5'b00000);
			default: ccrMask = CUNUSED;
		endcase
	end
	always @(*) begin
		if (_sv2v_0)
			;
		if (finish)
			ccrMask1 = (row[7] ? KNZ00 : KNZKK);
		else
			ccrMask1 = (row[13] | row[14] ? KKZKK : KNZ00);
	end
	initial _sv2v_0 = 0;
endmodule
module pla_lined (
	movEa,
	col,
	opcode,
	lineBmap,
	palIll,
	plaA1,
	plaA2,
	plaA3
);
	reg _sv2v_0;
	input [3:0] movEa;
	input [3:0] col;
	input [15:0] opcode;
	input [15:0] lineBmap;
	output wire palIll;
	output wire [9:0] plaA1;
	output wire [9:0] plaA2;
	output wire [9:0] plaA3;
	wire [3:0] line = opcode[15:12];
	wire [2:0] row86 = opcode[8:6];
	reg [15:0] arIll;
	reg [9:0] arA1 [15:0];
	reg [9:0] arA23 [15:0];
	reg [9:0] scA3;
	reg illMisc;
	reg [9:0] a1Misc;
	assign palIll = |(arIll & lineBmap);
	assign plaA1 = arA1[line];
	assign plaA2 = arA23[line];
	assign plaA3 = (lineBmap[0] ? scA3 : arA23[line]);
	always @(*) begin
		if (_sv2v_0)
			;
		arIll['h6] = 1'b0;
		arA23['h6] = 1'sbx;
		if (opcode[11:8] == 4'h1)
			arA1['h6] = (|opcode[7:0] ? 'h89 : 'ha9);
		else
			arA1['h6] = (|opcode[7:0] ? 'h308 : 'h68);
		arIll['h7] = opcode[8];
		arA23['h7] = 1'sbx;
		arA1['h7] = 'h23b;
		arIll['ha] = 1'b1;
		arIll['hf] = 1'b1;
		arA1['ha] = 1'sbx;
		arA1['hf] = 1'sbx;
		arA23['ha] = 1'sbx;
		arA23['hf] = 1'sbx;
	end
	always @(*) begin
		if (_sv2v_0)
			;
		if ((~opcode[11] & opcode[7]) & opcode[6]) begin
			arA23['he] = 'h3c7;
			(* full_case, parallel_case *)
			case (col)
				2: begin
					arIll['he] = 1'b0;
					arA1['he] = 'h6;
				end
				3: begin
					arIll['he] = 1'b0;
					arA1['he] = 'h21c;
				end
				4: begin
					arIll['he] = 1'b0;
					arA1['he] = 'h103;
				end
				5: begin
					arIll['he] = 1'b0;
					arA1['he] = 'h1c2;
				end
				6: begin
					arIll['he] = 1'b0;
					arA1['he] = 'h1e3;
				end
				7: begin
					arIll['he] = 1'b0;
					arA1['he] = 'ha;
				end
				8: begin
					arIll['he] = 1'b0;
					arA1['he] = 'h1e2;
				end
				default: begin
					arIll['he] = 1'b1;
					arA1['he] = 1'sbx;
				end
			endcase
		end
		else begin
			arA23['he] = 1'sbx;
			(* full_case, parallel_case *)
			case (opcode[7:6])
				2'b00, 2'b01: begin
					arIll['he] = 1'b0;
					arA1['he] = (opcode[5] ? 'h382 : 'h381);
				end
				2'b10: begin
					arIll['he] = 1'b0;
					arA1['he] = (opcode[5] ? 'h386 : 'h385);
				end
				2'b11: begin
					arIll['he] = 1'b1;
					arA1['he] = 1'sbx;
				end
			endcase
		end
	end
	always @(*) begin
		if (_sv2v_0)
			;
		illMisc = 1'b0;
		case (opcode[5:3])
			3'b000, 3'b001: a1Misc = 'h1d0;
			3'b010: a1Misc = 'h30b;
			3'b011: a1Misc = 'h119;
			3'b100: a1Misc = 'h2f5;
			3'b101: a1Misc = 'h230;
			3'b110:
				case (opcode[2:0])
					3'b110: a1Misc = 'h6d;
					3'b000: a1Misc = 'h3a6;
					3'b001: a1Misc = 'h363;
					3'b010: a1Misc = 'h3a2;
					3'b011: a1Misc = 'h12a;
					3'b111: a1Misc = 'h12a;
					3'b101: a1Misc = 'h126;
					default: begin
						illMisc = 1'b1;
						a1Misc = 1'sbx;
					end
				endcase
			default: begin
				illMisc = 1'b1;
				a1Misc = 1'sbx;
			end
		endcase
	end
	always @(*) begin
		if (_sv2v_0)
			;
		if ((opcode[11:6] & 'h1f) == 'h8)
			(* full_case, parallel_case *)
			case (col)
				0: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'h100;
					scA3 = 1'sbx;
				end
				1: begin
					arIll['h0] = 1'b1;
					arA1['h0] = 1'sbx;
					arA23['h0] = 1'sbx;
					scA3 = 1'sbx;
				end
				2: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'h6;
					scA3 = 'h299;
				end
				3: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'h21c;
					scA3 = 'h299;
				end
				4: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'h103;
					scA3 = 'h299;
				end
				5: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'h1c2;
					scA3 = 'h299;
				end
				6: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'h1e3;
					scA3 = 'h299;
				end
				7: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'ha;
					scA3 = 'h299;
				end
				8: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'h1e2;
					scA3 = 'h299;
				end
				9: begin
					arIll['h0] = 1'b1;
					arA1['h0] = 1'sbx;
					arA23['h0] = 1'sbx;
					scA3 = 1'sbx;
				end
				10: begin
					arIll['h0] = 1'b1;
					arA1['h0] = 1'sbx;
					arA23['h0] = 1'sbx;
					scA3 = 1'sbx;
				end
				11: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'h1cc;
					scA3 = 1'sbx;
				end
				default: begin
					arIll['h0] = 1'b1;
					arA1['h0] = 1'sbx;
					arA23['h0] = 1'sbx;
					scA3 = 1'sbx;
				end
			endcase
		else if ((opcode[11:6] & 'h37) == 'h0)
			(* full_case, parallel_case *)
			case (col)
				0: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'h100;
					scA3 = 1'sbx;
				end
				1: begin
					arIll['h0] = 1'b1;
					arA1['h0] = 1'sbx;
					arA23['h0] = 1'sbx;
					scA3 = 1'sbx;
				end
				2: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'h6;
					scA3 = 'h299;
				end
				3: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'h21c;
					scA3 = 'h299;
				end
				4: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'h103;
					scA3 = 'h299;
				end
				5: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'h1c2;
					scA3 = 'h299;
				end
				6: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'h1e3;
					scA3 = 'h299;
				end
				7: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'ha;
					scA3 = 'h299;
				end
				8: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'h1e2;
					scA3 = 'h299;
				end
				9: begin
					arIll['h0] = 1'b1;
					arA1['h0] = 1'sbx;
					arA23['h0] = 1'sbx;
					scA3 = 1'sbx;
				end
				10: begin
					arIll['h0] = 1'b1;
					arA1['h0] = 1'sbx;
					arA23['h0] = 1'sbx;
					scA3 = 1'sbx;
				end
				11: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'h1cc;
					scA3 = 1'sbx;
				end
				default: begin
					arIll['h0] = 1'b1;
					arA1['h0] = 1'sbx;
					arA23['h0] = 1'sbx;
					scA3 = 1'sbx;
				end
			endcase
		else if ((opcode[11:6] & 'h1f) == 'h9)
			(* full_case, parallel_case *)
			case (col)
				0: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'h100;
					scA3 = 1'sbx;
				end
				1: begin
					arIll['h0] = 1'b1;
					arA1['h0] = 1'sbx;
					arA23['h0] = 1'sbx;
					scA3 = 1'sbx;
				end
				2: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'h6;
					scA3 = 'h299;
				end
				3: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'h21c;
					scA3 = 'h299;
				end
				4: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'h103;
					scA3 = 'h299;
				end
				5: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'h1c2;
					scA3 = 'h299;
				end
				6: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'h1e3;
					scA3 = 'h299;
				end
				7: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'ha;
					scA3 = 'h299;
				end
				8: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'h1e2;
					scA3 = 'h299;
				end
				9: begin
					arIll['h0] = 1'b1;
					arA1['h0] = 1'sbx;
					arA23['h0] = 1'sbx;
					scA3 = 1'sbx;
				end
				10: begin
					arIll['h0] = 1'b1;
					arA1['h0] = 1'sbx;
					arA23['h0] = 1'sbx;
					scA3 = 1'sbx;
				end
				11: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'h1cc;
					scA3 = 1'sbx;
				end
				default: begin
					arIll['h0] = 1'b1;
					arA1['h0] = 1'sbx;
					arA23['h0] = 1'sbx;
					scA3 = 1'sbx;
				end
			endcase
		else if ((opcode[11:6] & 'h37) == 'h1)
			(* full_case, parallel_case *)
			case (col)
				0: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'h100;
					scA3 = 1'sbx;
				end
				1: begin
					arIll['h0] = 1'b1;
					arA1['h0] = 1'sbx;
					arA23['h0] = 1'sbx;
					scA3 = 1'sbx;
				end
				2: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'h6;
					scA3 = 'h299;
				end
				3: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'h21c;
					scA3 = 'h299;
				end
				4: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'h103;
					scA3 = 'h299;
				end
				5: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'h1c2;
					scA3 = 'h299;
				end
				6: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'h1e3;
					scA3 = 'h299;
				end
				7: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'ha;
					scA3 = 'h299;
				end
				8: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'h1e2;
					scA3 = 'h299;
				end
				9: begin
					arIll['h0] = 1'b1;
					arA1['h0] = 1'sbx;
					arA23['h0] = 1'sbx;
					scA3 = 1'sbx;
				end
				10: begin
					arIll['h0] = 1'b1;
					arA1['h0] = 1'sbx;
					arA23['h0] = 1'sbx;
					scA3 = 1'sbx;
				end
				11: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'h1cc;
					scA3 = 1'sbx;
				end
				default: begin
					arIll['h0] = 1'b1;
					arA1['h0] = 1'sbx;
					arA23['h0] = 1'sbx;
					scA3 = 1'sbx;
				end
			endcase
		else if ((opcode[11:6] & 'h1f) == 'ha)
			(* full_case, parallel_case *)
			case (col)
				0: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h3e0;
					arA23['h0] = 'h10c;
					scA3 = 1'sbx;
				end
				1: begin
					arIll['h0] = 1'b1;
					arA1['h0] = 1'sbx;
					arA23['h0] = 1'sbx;
					scA3 = 1'sbx;
				end
				2: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h3e0;
					arA23['h0] = 'hb;
					scA3 = 'h29d;
				end
				3: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h3e0;
					arA23['h0] = 'hf;
					scA3 = 'h29d;
				end
				4: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h3e0;
					arA23['h0] = 'h179;
					scA3 = 'h29d;
				end
				5: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h3e0;
					arA23['h0] = 'h1c6;
					scA3 = 'h29d;
				end
				6: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h3e0;
					arA23['h0] = 'h1e7;
					scA3 = 'h29d;
				end
				7: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h3e0;
					arA23['h0] = 'he;
					scA3 = 'h29d;
				end
				8: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h3e0;
					arA23['h0] = 'h1e6;
					scA3 = 'h29d;
				end
				9: begin
					arIll['h0] = 1'b1;
					arA1['h0] = 1'sbx;
					arA23['h0] = 1'sbx;
					scA3 = 1'sbx;
				end
				10: begin
					arIll['h0] = 1'b1;
					arA1['h0] = 1'sbx;
					arA23['h0] = 1'sbx;
					scA3 = 1'sbx;
				end
				11: begin
					arIll['h0] = 1'b1;
					arA1['h0] = 1'sbx;
					arA23['h0] = 1'sbx;
					scA3 = 1'sbx;
				end
				default: begin
					arIll['h0] = 1'b1;
					arA1['h0] = 1'sbx;
					arA23['h0] = 1'sbx;
					scA3 = 1'sbx;
				end
			endcase
		else if ((opcode[11:6] & 'h37) == 'h2)
			(* full_case, parallel_case *)
			case (col)
				0: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h3e0;
					arA23['h0] = 'h10c;
					scA3 = 1'sbx;
				end
				1: begin
					arIll['h0] = 1'b1;
					arA1['h0] = 1'sbx;
					arA23['h0] = 1'sbx;
					scA3 = 1'sbx;
				end
				2: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h3e0;
					arA23['h0] = 'hb;
					scA3 = 'h29d;
				end
				3: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h3e0;
					arA23['h0] = 'hf;
					scA3 = 'h29d;
				end
				4: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h3e0;
					arA23['h0] = 'h179;
					scA3 = 'h29d;
				end
				5: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h3e0;
					arA23['h0] = 'h1c6;
					scA3 = 'h29d;
				end
				6: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h3e0;
					arA23['h0] = 'h1e7;
					scA3 = 'h29d;
				end
				7: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h3e0;
					arA23['h0] = 'he;
					scA3 = 'h29d;
				end
				8: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h3e0;
					arA23['h0] = 'h1e6;
					scA3 = 'h29d;
				end
				9: begin
					arIll['h0] = 1'b1;
					arA1['h0] = 1'sbx;
					arA23['h0] = 1'sbx;
					scA3 = 1'sbx;
				end
				10: begin
					arIll['h0] = 1'b1;
					arA1['h0] = 1'sbx;
					arA23['h0] = 1'sbx;
					scA3 = 1'sbx;
				end
				11: begin
					arIll['h0] = 1'b1;
					arA1['h0] = 1'sbx;
					arA23['h0] = 1'sbx;
					scA3 = 1'sbx;
				end
				default: begin
					arIll['h0] = 1'b1;
					arA1['h0] = 1'sbx;
					arA23['h0] = 1'sbx;
					scA3 = 1'sbx;
				end
			endcase
		else if ((opcode[11:6] & 'h37) == 'h10)
			(* full_case, parallel_case *)
			case (col)
				0: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'h100;
					scA3 = 1'sbx;
				end
				1: begin
					arIll['h0] = 1'b1;
					arA1['h0] = 1'sbx;
					arA23['h0] = 1'sbx;
					scA3 = 1'sbx;
				end
				2: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'h6;
					scA3 = 'h299;
				end
				3: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'h21c;
					scA3 = 'h299;
				end
				4: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'h103;
					scA3 = 'h299;
				end
				5: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'h1c2;
					scA3 = 'h299;
				end
				6: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'h1e3;
					scA3 = 'h299;
				end
				7: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'ha;
					scA3 = 'h299;
				end
				8: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'h1e2;
					scA3 = 'h299;
				end
				9: begin
					arIll['h0] = 1'b1;
					arA1['h0] = 1'sbx;
					arA23['h0] = 1'sbx;
					scA3 = 1'sbx;
				end
				10: begin
					arIll['h0] = 1'b1;
					arA1['h0] = 1'sbx;
					arA23['h0] = 1'sbx;
					scA3 = 1'sbx;
				end
				11: begin
					arIll['h0] = 1'b1;
					arA1['h0] = 1'sbx;
					arA23['h0] = 1'sbx;
					scA3 = 1'sbx;
				end
				default: begin
					arIll['h0] = 1'b1;
					arA1['h0] = 1'sbx;
					arA23['h0] = 1'sbx;
					scA3 = 1'sbx;
				end
			endcase
		else if ((opcode[11:6] & 'h37) == 'h11)
			(* full_case, parallel_case *)
			case (col)
				0: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'h100;
					scA3 = 1'sbx;
				end
				1: begin
					arIll['h0] = 1'b1;
					arA1['h0] = 1'sbx;
					arA23['h0] = 1'sbx;
					scA3 = 1'sbx;
				end
				2: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'h6;
					scA3 = 'h299;
				end
				3: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'h21c;
					scA3 = 'h299;
				end
				4: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'h103;
					scA3 = 'h299;
				end
				5: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'h1c2;
					scA3 = 'h299;
				end
				6: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'h1e3;
					scA3 = 'h299;
				end
				7: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'ha;
					scA3 = 'h299;
				end
				8: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'h1e2;
					scA3 = 'h299;
				end
				9: begin
					arIll['h0] = 1'b1;
					arA1['h0] = 1'sbx;
					arA23['h0] = 1'sbx;
					scA3 = 1'sbx;
				end
				10: begin
					arIll['h0] = 1'b1;
					arA1['h0] = 1'sbx;
					arA23['h0] = 1'sbx;
					scA3 = 1'sbx;
				end
				11: begin
					arIll['h0] = 1'b1;
					arA1['h0] = 1'sbx;
					arA23['h0] = 1'sbx;
					scA3 = 1'sbx;
				end
				default: begin
					arIll['h0] = 1'b1;
					arA1['h0] = 1'sbx;
					arA23['h0] = 1'sbx;
					scA3 = 1'sbx;
				end
			endcase
		else if ((opcode[11:6] & 'h37) == 'h12)
			(* full_case, parallel_case *)
			case (col)
				0: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h3e0;
					arA23['h0] = 'h10c;
					scA3 = 1'sbx;
				end
				1: begin
					arIll['h0] = 1'b1;
					arA1['h0] = 1'sbx;
					arA23['h0] = 1'sbx;
					scA3 = 1'sbx;
				end
				2: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h3e0;
					arA23['h0] = 'hb;
					scA3 = 'h29d;
				end
				3: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h3e0;
					arA23['h0] = 'hf;
					scA3 = 'h29d;
				end
				4: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h3e0;
					arA23['h0] = 'h179;
					scA3 = 'h29d;
				end
				5: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h3e0;
					arA23['h0] = 'h1c6;
					scA3 = 'h29d;
				end
				6: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h3e0;
					arA23['h0] = 'h1e7;
					scA3 = 'h29d;
				end
				7: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h3e0;
					arA23['h0] = 'he;
					scA3 = 'h29d;
				end
				8: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h3e0;
					arA23['h0] = 'h1e6;
					scA3 = 'h29d;
				end
				9: begin
					arIll['h0] = 1'b1;
					arA1['h0] = 1'sbx;
					arA23['h0] = 1'sbx;
					scA3 = 1'sbx;
				end
				10: begin
					arIll['h0] = 1'b1;
					arA1['h0] = 1'sbx;
					arA23['h0] = 1'sbx;
					scA3 = 1'sbx;
				end
				11: begin
					arIll['h0] = 1'b1;
					arA1['h0] = 1'sbx;
					arA23['h0] = 1'sbx;
					scA3 = 1'sbx;
				end
				default: begin
					arIll['h0] = 1'b1;
					arA1['h0] = 1'sbx;
					arA23['h0] = 1'sbx;
					scA3 = 1'sbx;
				end
			endcase
		else if ((opcode[11:6] & 'h7) == 'h4)
			(* full_case, parallel_case *)
			case (col)
				0: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h3e7;
					arA23['h0] = 1'sbx;
					scA3 = 1'sbx;
				end
				1: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h1d2;
					arA23['h0] = 1'sbx;
					scA3 = 1'sbx;
				end
				2: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h6;
					arA23['h0] = 1'sbx;
					scA3 = 'h215;
				end
				3: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h21c;
					arA23['h0] = 1'sbx;
					scA3 = 'h215;
				end
				4: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h103;
					arA23['h0] = 1'sbx;
					scA3 = 'h215;
				end
				5: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h1c2;
					arA23['h0] = 1'sbx;
					scA3 = 'h215;
				end
				6: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h1e3;
					arA23['h0] = 1'sbx;
					scA3 = 'h215;
				end
				7: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'ha;
					arA23['h0] = 1'sbx;
					scA3 = 'h215;
				end
				8: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h1e2;
					arA23['h0] = 1'sbx;
					scA3 = 'h215;
				end
				9: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h1c2;
					arA23['h0] = 1'sbx;
					scA3 = 'h215;
				end
				10: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h1e3;
					arA23['h0] = 1'sbx;
					scA3 = 'h215;
				end
				11: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'hea;
					arA23['h0] = 'hab;
					scA3 = 1'sbx;
				end
				default: begin
					arIll['h0] = 1'b1;
					arA1['h0] = 1'sbx;
					arA23['h0] = 1'sbx;
					scA3 = 1'sbx;
				end
			endcase
		else if ((opcode[11:6] & 'h7) == 'h5)
			(* full_case, parallel_case *)
			case (col)
				0: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h3ef;
					arA23['h0] = 1'sbx;
					scA3 = 1'sbx;
				end
				1: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h1d6;
					arA23['h0] = 1'sbx;
					scA3 = 1'sbx;
				end
				2: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h6;
					arA23['h0] = 1'sbx;
					scA3 = 'h81;
				end
				3: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h21c;
					arA23['h0] = 1'sbx;
					scA3 = 'h81;
				end
				4: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h103;
					arA23['h0] = 1'sbx;
					scA3 = 'h81;
				end
				5: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h1c2;
					arA23['h0] = 1'sbx;
					scA3 = 'h81;
				end
				6: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h1e3;
					arA23['h0] = 1'sbx;
					scA3 = 'h81;
				end
				7: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'ha;
					arA23['h0] = 1'sbx;
					scA3 = 'h81;
				end
				8: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h1e2;
					arA23['h0] = 1'sbx;
					scA3 = 'h81;
				end
				9: begin
					arIll['h0] = 1'b1;
					arA1['h0] = 1'sbx;
					arA23['h0] = 1'sbx;
					scA3 = 1'sbx;
				end
				10: begin
					arIll['h0] = 1'b1;
					arA1['h0] = 1'sbx;
					arA23['h0] = 1'sbx;
					scA3 = 1'sbx;
				end
				11: begin
					arIll['h0] = 1'b1;
					arA1['h0] = 1'sbx;
					arA23['h0] = 1'sbx;
					scA3 = 1'sbx;
				end
				default: begin
					arIll['h0] = 1'b1;
					arA1['h0] = 1'sbx;
					arA23['h0] = 1'sbx;
					scA3 = 1'sbx;
				end
			endcase
		else if ((opcode[11:6] & 'h7) == 'h7)
			(* full_case, parallel_case *)
			case (col)
				0: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h3ef;
					arA23['h0] = 1'sbx;
					scA3 = 1'sbx;
				end
				1: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h1ce;
					arA23['h0] = 1'sbx;
					scA3 = 1'sbx;
				end
				2: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h6;
					arA23['h0] = 1'sbx;
					scA3 = 'h81;
				end
				3: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h21c;
					arA23['h0] = 1'sbx;
					scA3 = 'h81;
				end
				4: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h103;
					arA23['h0] = 1'sbx;
					scA3 = 'h81;
				end
				5: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h1c2;
					arA23['h0] = 1'sbx;
					scA3 = 'h81;
				end
				6: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h1e3;
					arA23['h0] = 1'sbx;
					scA3 = 'h81;
				end
				7: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'ha;
					arA23['h0] = 1'sbx;
					scA3 = 'h81;
				end
				8: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h1e2;
					arA23['h0] = 1'sbx;
					scA3 = 'h81;
				end
				9: begin
					arIll['h0] = 1'b1;
					arA1['h0] = 1'sbx;
					arA23['h0] = 1'sbx;
					scA3 = 1'sbx;
				end
				10: begin
					arIll['h0] = 1'b1;
					arA1['h0] = 1'sbx;
					arA23['h0] = 1'sbx;
					scA3 = 1'sbx;
				end
				11: begin
					arIll['h0] = 1'b1;
					arA1['h0] = 1'sbx;
					arA23['h0] = 1'sbx;
					scA3 = 1'sbx;
				end
				default: begin
					arIll['h0] = 1'b1;
					arA1['h0] = 1'sbx;
					arA23['h0] = 1'sbx;
					scA3 = 1'sbx;
				end
			endcase
		else if ((opcode[11:6] & 'h7) == 'h6)
			(* full_case, parallel_case *)
			case (col)
				0: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h3eb;
					arA23['h0] = 1'sbx;
					scA3 = 1'sbx;
				end
				1: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h1ca;
					arA23['h0] = 1'sbx;
					scA3 = 1'sbx;
				end
				2: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h6;
					arA23['h0] = 1'sbx;
					scA3 = 'h69;
				end
				3: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h21c;
					arA23['h0] = 1'sbx;
					scA3 = 'h69;
				end
				4: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h103;
					arA23['h0] = 1'sbx;
					scA3 = 'h69;
				end
				5: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h1c2;
					arA23['h0] = 1'sbx;
					scA3 = 'h69;
				end
				6: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h1e3;
					arA23['h0] = 1'sbx;
					scA3 = 'h69;
				end
				7: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'ha;
					arA23['h0] = 1'sbx;
					scA3 = 'h69;
				end
				8: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h1e2;
					arA23['h0] = 1'sbx;
					scA3 = 'h69;
				end
				9: begin
					arIll['h0] = 1'b1;
					arA1['h0] = 1'sbx;
					arA23['h0] = 1'sbx;
					scA3 = 1'sbx;
				end
				10: begin
					arIll['h0] = 1'b1;
					arA1['h0] = 1'sbx;
					arA23['h0] = 1'sbx;
					scA3 = 1'sbx;
				end
				11: begin
					arIll['h0] = 1'b1;
					arA1['h0] = 1'sbx;
					arA23['h0] = 1'sbx;
					scA3 = 1'sbx;
				end
				default: begin
					arIll['h0] = 1'b1;
					arA1['h0] = 1'sbx;
					arA23['h0] = 1'sbx;
					scA3 = 1'sbx;
				end
			endcase
		else if (opcode[11:6] == 'h20)
			(* full_case, parallel_case *)
			case (col)
				0: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'h3e7;
					scA3 = 1'sbx;
				end
				1: begin
					arIll['h0] = 1'b1;
					arA1['h0] = 1'sbx;
					arA23['h0] = 1'sbx;
					scA3 = 1'sbx;
				end
				2: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'h6;
					scA3 = 'h215;
				end
				3: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'h21c;
					scA3 = 'h215;
				end
				4: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'h103;
					scA3 = 'h215;
				end
				5: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'h1c2;
					scA3 = 'h215;
				end
				6: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'h1e3;
					scA3 = 'h215;
				end
				7: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'ha;
					scA3 = 'h215;
				end
				8: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'h1e2;
					scA3 = 'h215;
				end
				9: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'h1c2;
					scA3 = 'h215;
				end
				10: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'h1e3;
					scA3 = 'h215;
				end
				11: begin
					arIll['h0] = 1'b1;
					arA1['h0] = 1'sbx;
					arA23['h0] = 1'sbx;
					scA3 = 1'sbx;
				end
				default: begin
					arIll['h0] = 1'b1;
					arA1['h0] = 1'sbx;
					arA23['h0] = 1'sbx;
					scA3 = 1'sbx;
				end
			endcase
		else if (opcode[11:6] == 'h21)
			(* full_case, parallel_case *)
			case (col)
				0: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'h3ef;
					scA3 = 1'sbx;
				end
				1: begin
					arIll['h0] = 1'b1;
					arA1['h0] = 1'sbx;
					arA23['h0] = 1'sbx;
					scA3 = 1'sbx;
				end
				2: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'h6;
					scA3 = 'h81;
				end
				3: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'h21c;
					scA3 = 'h81;
				end
				4: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'h103;
					scA3 = 'h81;
				end
				5: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'h1c2;
					scA3 = 'h81;
				end
				6: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'h1e3;
					scA3 = 'h81;
				end
				7: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'ha;
					scA3 = 'h81;
				end
				8: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'h1e2;
					scA3 = 'h81;
				end
				9: begin
					arIll['h0] = 1'b1;
					arA1['h0] = 1'sbx;
					arA23['h0] = 1'sbx;
					scA3 = 1'sbx;
				end
				10: begin
					arIll['h0] = 1'b1;
					arA1['h0] = 1'sbx;
					arA23['h0] = 1'sbx;
					scA3 = 1'sbx;
				end
				11: begin
					arIll['h0] = 1'b1;
					arA1['h0] = 1'sbx;
					arA23['h0] = 1'sbx;
					scA3 = 1'sbx;
				end
				default: begin
					arIll['h0] = 1'b1;
					arA1['h0] = 1'sbx;
					arA23['h0] = 1'sbx;
					scA3 = 1'sbx;
				end
			endcase
		else if (opcode[11:6] == 'h23)
			(* full_case, parallel_case *)
			case (col)
				0: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'h3ef;
					scA3 = 1'sbx;
				end
				1: begin
					arIll['h0] = 1'b1;
					arA1['h0] = 1'sbx;
					arA23['h0] = 1'sbx;
					scA3 = 1'sbx;
				end
				2: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'h6;
					scA3 = 'h81;
				end
				3: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'h21c;
					scA3 = 'h81;
				end
				4: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'h103;
					scA3 = 'h81;
				end
				5: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'h1c2;
					scA3 = 'h81;
				end
				6: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'h1e3;
					scA3 = 'h81;
				end
				7: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'ha;
					scA3 = 'h81;
				end
				8: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'h1e2;
					scA3 = 'h81;
				end
				9: begin
					arIll['h0] = 1'b1;
					arA1['h0] = 1'sbx;
					arA23['h0] = 1'sbx;
					scA3 = 1'sbx;
				end
				10: begin
					arIll['h0] = 1'b1;
					arA1['h0] = 1'sbx;
					arA23['h0] = 1'sbx;
					scA3 = 1'sbx;
				end
				11: begin
					arIll['h0] = 1'b1;
					arA1['h0] = 1'sbx;
					arA23['h0] = 1'sbx;
					scA3 = 1'sbx;
				end
				default: begin
					arIll['h0] = 1'b1;
					arA1['h0] = 1'sbx;
					arA23['h0] = 1'sbx;
					scA3 = 1'sbx;
				end
			endcase
		else if (opcode[11:6] == 'h22)
			(* full_case, parallel_case *)
			case (col)
				0: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'h3eb;
					scA3 = 1'sbx;
				end
				1: begin
					arIll['h0] = 1'b1;
					arA1['h0] = 1'sbx;
					arA23['h0] = 1'sbx;
					scA3 = 1'sbx;
				end
				2: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'h6;
					scA3 = 'h69;
				end
				3: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'h21c;
					scA3 = 'h69;
				end
				4: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'h103;
					scA3 = 'h69;
				end
				5: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'h1c2;
					scA3 = 'h69;
				end
				6: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'h1e3;
					scA3 = 'h69;
				end
				7: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'ha;
					scA3 = 'h69;
				end
				8: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'h1e2;
					scA3 = 'h69;
				end
				9: begin
					arIll['h0] = 1'b1;
					arA1['h0] = 1'sbx;
					arA23['h0] = 1'sbx;
					scA3 = 1'sbx;
				end
				10: begin
					arIll['h0] = 1'b1;
					arA1['h0] = 1'sbx;
					arA23['h0] = 1'sbx;
					scA3 = 1'sbx;
				end
				11: begin
					arIll['h0] = 1'b1;
					arA1['h0] = 1'sbx;
					arA23['h0] = 1'sbx;
					scA3 = 1'sbx;
				end
				default: begin
					arIll['h0] = 1'b1;
					arA1['h0] = 1'sbx;
					arA23['h0] = 1'sbx;
					scA3 = 1'sbx;
				end
			endcase
		else if (opcode[11:6] == 'h30)
			(* full_case, parallel_case *)
			case (col)
				0: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'h108;
					scA3 = 1'sbx;
				end
				1: begin
					arIll['h0] = 1'b1;
					arA1['h0] = 1'sbx;
					arA23['h0] = 1'sbx;
					scA3 = 1'sbx;
				end
				2: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'h6;
					scA3 = 'h87;
				end
				3: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'h21c;
					scA3 = 'h87;
				end
				4: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'h103;
					scA3 = 'h87;
				end
				5: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'h1c2;
					scA3 = 'h87;
				end
				6: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'h1e3;
					scA3 = 'h87;
				end
				7: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'ha;
					scA3 = 'h87;
				end
				8: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'h1e2;
					scA3 = 'h87;
				end
				9: begin
					arIll['h0] = 1'b1;
					arA1['h0] = 1'sbx;
					arA23['h0] = 1'sbx;
					scA3 = 1'sbx;
				end
				10: begin
					arIll['h0] = 1'b1;
					arA1['h0] = 1'sbx;
					arA23['h0] = 1'sbx;
					scA3 = 1'sbx;
				end
				11: begin
					arIll['h0] = 1'b1;
					arA1['h0] = 1'sbx;
					arA23['h0] = 1'sbx;
					scA3 = 1'sbx;
				end
				default: begin
					arIll['h0] = 1'b1;
					arA1['h0] = 1'sbx;
					arA23['h0] = 1'sbx;
					scA3 = 1'sbx;
				end
			endcase
		else if (opcode[11:6] == 'h31)
			(* full_case, parallel_case *)
			case (col)
				0: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'h108;
					scA3 = 1'sbx;
				end
				1: begin
					arIll['h0] = 1'b1;
					arA1['h0] = 1'sbx;
					arA23['h0] = 1'sbx;
					scA3 = 1'sbx;
				end
				2: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'h6;
					scA3 = 'h87;
				end
				3: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'h21c;
					scA3 = 'h87;
				end
				4: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'h103;
					scA3 = 'h87;
				end
				5: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'h1c2;
					scA3 = 'h87;
				end
				6: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'h1e3;
					scA3 = 'h87;
				end
				7: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'ha;
					scA3 = 'h87;
				end
				8: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h2b9;
					arA23['h0] = 'h1e2;
					scA3 = 'h87;
				end
				9: begin
					arIll['h0] = 1'b1;
					arA1['h0] = 1'sbx;
					arA23['h0] = 1'sbx;
					scA3 = 1'sbx;
				end
				10: begin
					arIll['h0] = 1'b1;
					arA1['h0] = 1'sbx;
					arA23['h0] = 1'sbx;
					scA3 = 1'sbx;
				end
				11: begin
					arIll['h0] = 1'b1;
					arA1['h0] = 1'sbx;
					arA23['h0] = 1'sbx;
					scA3 = 1'sbx;
				end
				default: begin
					arIll['h0] = 1'b1;
					arA1['h0] = 1'sbx;
					arA23['h0] = 1'sbx;
					scA3 = 1'sbx;
				end
			endcase
		else if (opcode[11:6] == 'h32)
			(* full_case, parallel_case *)
			case (col)
				0: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h3e0;
					arA23['h0] = 'h104;
					scA3 = 1'sbx;
				end
				1: begin
					arIll['h0] = 1'b1;
					arA1['h0] = 1'sbx;
					arA23['h0] = 1'sbx;
					scA3 = 1'sbx;
				end
				2: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h3e0;
					arA23['h0] = 'hb;
					scA3 = 'h8f;
				end
				3: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h3e0;
					arA23['h0] = 'hf;
					scA3 = 'h8f;
				end
				4: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h3e0;
					arA23['h0] = 'h179;
					scA3 = 'h8f;
				end
				5: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h3e0;
					arA23['h0] = 'h1c6;
					scA3 = 'h8f;
				end
				6: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h3e0;
					arA23['h0] = 'h1e7;
					scA3 = 'h8f;
				end
				7: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h3e0;
					arA23['h0] = 'he;
					scA3 = 'h8f;
				end
				8: begin
					arIll['h0] = 1'b0;
					arA1['h0] = 'h3e0;
					arA23['h0] = 'h1e6;
					scA3 = 'h8f;
				end
				9: begin
					arIll['h0] = 1'b1;
					arA1['h0] = 1'sbx;
					arA23['h0] = 1'sbx;
					scA3 = 1'sbx;
				end
				10: begin
					arIll['h0] = 1'b1;
					arA1['h0] = 1'sbx;
					arA23['h0] = 1'sbx;
					scA3 = 1'sbx;
				end
				11: begin
					arIll['h0] = 1'b1;
					arA1['h0] = 1'sbx;
					arA23['h0] = 1'sbx;
					scA3 = 1'sbx;
				end
				default: begin
					arIll['h0] = 1'b1;
					arA1['h0] = 1'sbx;
					arA23['h0] = 1'sbx;
					scA3 = 1'sbx;
				end
			endcase
		else begin
			arIll['h0] = 1'b1;
			arA1['h0] = 1'sbx;
			arA23['h0] = 1'sbx;
			scA3 = 1'sbx;
		end
	end
	always @(*) begin
		if (_sv2v_0)
			;
		if ((opcode[11:6] & 'h27) == 'h0)
			(* full_case, parallel_case *)
			case (col)
				0: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h133;
					arA23['h4] = 1'sbx;
				end
				1: begin
					arIll['h4] = 1'b1;
					arA1['h4] = 1'sbx;
					arA23['h4] = 1'sbx;
				end
				2: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h6;
					arA23['h4] = 'h2b8;
				end
				3: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h21c;
					arA23['h4] = 'h2b8;
				end
				4: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h103;
					arA23['h4] = 'h2b8;
				end
				5: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h1c2;
					arA23['h4] = 'h2b8;
				end
				6: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h1e3;
					arA23['h4] = 'h2b8;
				end
				7: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'ha;
					arA23['h4] = 'h2b8;
				end
				8: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h1e2;
					arA23['h4] = 'h2b8;
				end
				9: begin
					arIll['h4] = 1'b1;
					arA1['h4] = 1'sbx;
					arA23['h4] = 1'sbx;
				end
				10: begin
					arIll['h4] = 1'b1;
					arA1['h4] = 1'sbx;
					arA23['h4] = 1'sbx;
				end
				11: begin
					arIll['h4] = 1'b1;
					arA1['h4] = 1'sbx;
					arA23['h4] = 1'sbx;
				end
				default: begin
					arIll['h4] = 1'b1;
					arA1['h4] = 1'sbx;
					arA23['h4] = 1'sbx;
				end
			endcase
		else if ((opcode[11:6] & 'h27) == 'h1)
			(* full_case, parallel_case *)
			case (col)
				0: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h133;
					arA23['h4] = 1'sbx;
				end
				1: begin
					arIll['h4] = 1'b1;
					arA1['h4] = 1'sbx;
					arA23['h4] = 1'sbx;
				end
				2: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h6;
					arA23['h4] = 'h2b8;
				end
				3: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h21c;
					arA23['h4] = 'h2b8;
				end
				4: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h103;
					arA23['h4] = 'h2b8;
				end
				5: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h1c2;
					arA23['h4] = 'h2b8;
				end
				6: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h1e3;
					arA23['h4] = 'h2b8;
				end
				7: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'ha;
					arA23['h4] = 'h2b8;
				end
				8: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h1e2;
					arA23['h4] = 'h2b8;
				end
				9: begin
					arIll['h4] = 1'b1;
					arA1['h4] = 1'sbx;
					arA23['h4] = 1'sbx;
				end
				10: begin
					arIll['h4] = 1'b1;
					arA1['h4] = 1'sbx;
					arA23['h4] = 1'sbx;
				end
				11: begin
					arIll['h4] = 1'b1;
					arA1['h4] = 1'sbx;
					arA23['h4] = 1'sbx;
				end
				default: begin
					arIll['h4] = 1'b1;
					arA1['h4] = 1'sbx;
					arA23['h4] = 1'sbx;
				end
			endcase
		else if ((opcode[11:6] & 'h27) == 'h2)
			(* full_case, parallel_case *)
			case (col)
				0: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h137;
					arA23['h4] = 1'sbx;
				end
				1: begin
					arIll['h4] = 1'b1;
					arA1['h4] = 1'sbx;
					arA23['h4] = 1'sbx;
				end
				2: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'hb;
					arA23['h4] = 'h2bc;
				end
				3: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'hf;
					arA23['h4] = 'h2bc;
				end
				4: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h179;
					arA23['h4] = 'h2bc;
				end
				5: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h1c6;
					arA23['h4] = 'h2bc;
				end
				6: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h1e7;
					arA23['h4] = 'h2bc;
				end
				7: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'he;
					arA23['h4] = 'h2bc;
				end
				8: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h1e6;
					arA23['h4] = 'h2bc;
				end
				9: begin
					arIll['h4] = 1'b1;
					arA1['h4] = 1'sbx;
					arA23['h4] = 1'sbx;
				end
				10: begin
					arIll['h4] = 1'b1;
					arA1['h4] = 1'sbx;
					arA23['h4] = 1'sbx;
				end
				11: begin
					arIll['h4] = 1'b1;
					arA1['h4] = 1'sbx;
					arA23['h4] = 1'sbx;
				end
				default: begin
					arIll['h4] = 1'b1;
					arA1['h4] = 1'sbx;
					arA23['h4] = 1'sbx;
				end
			endcase
		else if (opcode[11:6] == 'h3)
			(* full_case, parallel_case *)
			case (col)
				0: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h3a5;
					arA23['h4] = 1'sbx;
				end
				1: begin
					arIll['h4] = 1'b1;
					arA1['h4] = 1'sbx;
					arA23['h4] = 1'sbx;
				end
				2: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h6;
					arA23['h4] = 'h3a1;
				end
				3: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h21c;
					arA23['h4] = 'h3a1;
				end
				4: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h103;
					arA23['h4] = 'h3a1;
				end
				5: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h1c2;
					arA23['h4] = 'h3a1;
				end
				6: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h1e3;
					arA23['h4] = 'h3a1;
				end
				7: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'ha;
					arA23['h4] = 'h3a1;
				end
				8: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h1e2;
					arA23['h4] = 'h3a1;
				end
				9: begin
					arIll['h4] = 1'b1;
					arA1['h4] = 1'sbx;
					arA23['h4] = 1'sbx;
				end
				10: begin
					arIll['h4] = 1'b1;
					arA1['h4] = 1'sbx;
					arA23['h4] = 1'sbx;
				end
				11: begin
					arIll['h4] = 1'b1;
					arA1['h4] = 1'sbx;
					arA23['h4] = 1'sbx;
				end
				default: begin
					arIll['h4] = 1'b1;
					arA1['h4] = 1'sbx;
					arA23['h4] = 1'sbx;
				end
			endcase
		else if (opcode[11:6] == 'h13)
			(* full_case, parallel_case *)
			case (col)
				0: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h301;
					arA23['h4] = 1'sbx;
				end
				1: begin
					arIll['h4] = 1'b1;
					arA1['h4] = 1'sbx;
					arA23['h4] = 1'sbx;
				end
				2: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h6;
					arA23['h4] = 'h159;
				end
				3: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h21c;
					arA23['h4] = 'h159;
				end
				4: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h103;
					arA23['h4] = 'h159;
				end
				5: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h1c2;
					arA23['h4] = 'h159;
				end
				6: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h1e3;
					arA23['h4] = 'h159;
				end
				7: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'ha;
					arA23['h4] = 'h159;
				end
				8: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h1e2;
					arA23['h4] = 'h159;
				end
				9: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h1c2;
					arA23['h4] = 'h159;
				end
				10: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h1e3;
					arA23['h4] = 'h159;
				end
				11: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'hea;
					arA23['h4] = 'h301;
				end
				default: begin
					arIll['h4] = 1'b1;
					arA1['h4] = 1'sbx;
					arA23['h4] = 1'sbx;
				end
			endcase
		else if (opcode[11:6] == 'h1b)
			(* full_case, parallel_case *)
			case (col)
				0: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h301;
					arA23['h4] = 1'sbx;
				end
				1: begin
					arIll['h4] = 1'b1;
					arA1['h4] = 1'sbx;
					arA23['h4] = 1'sbx;
				end
				2: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h6;
					arA23['h4] = 'h159;
				end
				3: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h21c;
					arA23['h4] = 'h159;
				end
				4: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h103;
					arA23['h4] = 'h159;
				end
				5: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h1c2;
					arA23['h4] = 'h159;
				end
				6: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h1e3;
					arA23['h4] = 'h159;
				end
				7: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'ha;
					arA23['h4] = 'h159;
				end
				8: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h1e2;
					arA23['h4] = 'h159;
				end
				9: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h1c2;
					arA23['h4] = 'h159;
				end
				10: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h1e3;
					arA23['h4] = 'h159;
				end
				11: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'hea;
					arA23['h4] = 'h301;
				end
				default: begin
					arIll['h4] = 1'b1;
					arA1['h4] = 1'sbx;
					arA23['h4] = 1'sbx;
				end
			endcase
		else if (opcode[11:6] == 'h20)
			(* full_case, parallel_case *)
			case (col)
				0: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h13b;
					arA23['h4] = 1'sbx;
				end
				1: begin
					arIll['h4] = 1'b1;
					arA1['h4] = 1'sbx;
					arA23['h4] = 1'sbx;
				end
				2: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h6;
					arA23['h4] = 'h15c;
				end
				3: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h21c;
					arA23['h4] = 'h15c;
				end
				4: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h103;
					arA23['h4] = 'h15c;
				end
				5: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h1c2;
					arA23['h4] = 'h15c;
				end
				6: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h1e3;
					arA23['h4] = 'h15c;
				end
				7: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'ha;
					arA23['h4] = 'h15c;
				end
				8: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h1e2;
					arA23['h4] = 'h15c;
				end
				9: begin
					arIll['h4] = 1'b1;
					arA1['h4] = 1'sbx;
					arA23['h4] = 1'sbx;
				end
				10: begin
					arIll['h4] = 1'b1;
					arA1['h4] = 1'sbx;
					arA23['h4] = 1'sbx;
				end
				11: begin
					arIll['h4] = 1'b1;
					arA1['h4] = 1'sbx;
					arA23['h4] = 1'sbx;
				end
				default: begin
					arIll['h4] = 1'b1;
					arA1['h4] = 1'sbx;
					arA23['h4] = 1'sbx;
				end
			endcase
		else if (opcode[11:6] == 'h21)
			(* full_case, parallel_case *)
			case (col)
				0: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h341;
					arA23['h4] = 1'sbx;
				end
				1: begin
					arIll['h4] = 1'b1;
					arA1['h4] = 1'sbx;
					arA23['h4] = 1'sbx;
				end
				2: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h17c;
					arA23['h4] = 1'sbx;
				end
				3: begin
					arIll['h4] = 1'b1;
					arA1['h4] = 1'sbx;
					arA23['h4] = 1'sbx;
				end
				4: begin
					arIll['h4] = 1'b1;
					arA1['h4] = 1'sbx;
					arA23['h4] = 1'sbx;
				end
				5: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h17d;
					arA23['h4] = 1'sbx;
				end
				6: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h1ff;
					arA23['h4] = 1'sbx;
				end
				7: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h178;
					arA23['h4] = 1'sbx;
				end
				8: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h1fa;
					arA23['h4] = 1'sbx;
				end
				9: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h17d;
					arA23['h4] = 1'sbx;
				end
				10: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h1ff;
					arA23['h4] = 1'sbx;
				end
				11: begin
					arIll['h4] = 1'b1;
					arA1['h4] = 1'sbx;
					arA23['h4] = 1'sbx;
				end
				default: begin
					arIll['h4] = 1'b1;
					arA1['h4] = 1'sbx;
					arA23['h4] = 1'sbx;
				end
			endcase
		else if (opcode[11:6] == 'h22)
			(* full_case, parallel_case *)
			case (col)
				0: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h133;
					arA23['h4] = 1'sbx;
				end
				1: begin
					arIll['h4] = 1'b1;
					arA1['h4] = 1'sbx;
					arA23['h4] = 1'sbx;
				end
				2: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h3a0;
					arA23['h4] = 1'sbx;
				end
				3: begin
					arIll['h4] = 1'b1;
					arA1['h4] = 1'sbx;
					arA23['h4] = 1'sbx;
				end
				4: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h3a4;
					arA23['h4] = 1'sbx;
				end
				5: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h1f1;
					arA23['h4] = 1'sbx;
				end
				6: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h325;
					arA23['h4] = 1'sbx;
				end
				7: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h1ed;
					arA23['h4] = 1'sbx;
				end
				8: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h1e5;
					arA23['h4] = 1'sbx;
				end
				9: begin
					arIll['h4] = 1'b1;
					arA1['h4] = 1'sbx;
					arA23['h4] = 1'sbx;
				end
				10: begin
					arIll['h4] = 1'b1;
					arA1['h4] = 1'sbx;
					arA23['h4] = 1'sbx;
				end
				11: begin
					arIll['h4] = 1'b1;
					arA1['h4] = 1'sbx;
					arA23['h4] = 1'sbx;
				end
				default: begin
					arIll['h4] = 1'b1;
					arA1['h4] = 1'sbx;
					arA23['h4] = 1'sbx;
				end
			endcase
		else if (opcode[11:6] == 'h23)
			(* full_case, parallel_case *)
			case (col)
				0: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h232;
					arA23['h4] = 1'sbx;
				end
				1: begin
					arIll['h4] = 1'b1;
					arA1['h4] = 1'sbx;
					arA23['h4] = 1'sbx;
				end
				2: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h3a0;
					arA23['h4] = 1'sbx;
				end
				3: begin
					arIll['h4] = 1'b1;
					arA1['h4] = 1'sbx;
					arA23['h4] = 1'sbx;
				end
				4: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h3a4;
					arA23['h4] = 1'sbx;
				end
				5: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h1f1;
					arA23['h4] = 1'sbx;
				end
				6: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h325;
					arA23['h4] = 1'sbx;
				end
				7: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h1ed;
					arA23['h4] = 1'sbx;
				end
				8: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h1e5;
					arA23['h4] = 1'sbx;
				end
				9: begin
					arIll['h4] = 1'b1;
					arA1['h4] = 1'sbx;
					arA23['h4] = 1'sbx;
				end
				10: begin
					arIll['h4] = 1'b1;
					arA1['h4] = 1'sbx;
					arA23['h4] = 1'sbx;
				end
				11: begin
					arIll['h4] = 1'b1;
					arA1['h4] = 1'sbx;
					arA23['h4] = 1'sbx;
				end
				default: begin
					arIll['h4] = 1'b1;
					arA1['h4] = 1'sbx;
					arA23['h4] = 1'sbx;
				end
			endcase
		else if (opcode[11:6] == 'h28)
			(* full_case, parallel_case *)
			case (col)
				0: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h12d;
					arA23['h4] = 1'sbx;
				end
				1: begin
					arIll['h4] = 1'b1;
					arA1['h4] = 1'sbx;
					arA23['h4] = 1'sbx;
				end
				2: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h6;
					arA23['h4] = 'h3c3;
				end
				3: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h21c;
					arA23['h4] = 'h3c3;
				end
				4: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h103;
					arA23['h4] = 'h3c3;
				end
				5: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h1c2;
					arA23['h4] = 'h3c3;
				end
				6: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h1e3;
					arA23['h4] = 'h3c3;
				end
				7: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'ha;
					arA23['h4] = 'h3c3;
				end
				8: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h1e2;
					arA23['h4] = 'h3c3;
				end
				9: begin
					arIll['h4] = 1'b1;
					arA1['h4] = 1'sbx;
					arA23['h4] = 1'sbx;
				end
				10: begin
					arIll['h4] = 1'b1;
					arA1['h4] = 1'sbx;
					arA23['h4] = 1'sbx;
				end
				11: begin
					arIll['h4] = 1'b1;
					arA1['h4] = 1'sbx;
					arA23['h4] = 1'sbx;
				end
				default: begin
					arIll['h4] = 1'b1;
					arA1['h4] = 1'sbx;
					arA23['h4] = 1'sbx;
				end
			endcase
		else if (opcode[11:6] == 'h29)
			(* full_case, parallel_case *)
			case (col)
				0: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h12d;
					arA23['h4] = 1'sbx;
				end
				1: begin
					arIll['h4] = 1'b1;
					arA1['h4] = 1'sbx;
					arA23['h4] = 1'sbx;
				end
				2: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h6;
					arA23['h4] = 'h3c3;
				end
				3: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h21c;
					arA23['h4] = 'h3c3;
				end
				4: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h103;
					arA23['h4] = 'h3c3;
				end
				5: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h1c2;
					arA23['h4] = 'h3c3;
				end
				6: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h1e3;
					arA23['h4] = 'h3c3;
				end
				7: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'ha;
					arA23['h4] = 'h3c3;
				end
				8: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h1e2;
					arA23['h4] = 'h3c3;
				end
				9: begin
					arIll['h4] = 1'b1;
					arA1['h4] = 1'sbx;
					arA23['h4] = 1'sbx;
				end
				10: begin
					arIll['h4] = 1'b1;
					arA1['h4] = 1'sbx;
					arA23['h4] = 1'sbx;
				end
				11: begin
					arIll['h4] = 1'b1;
					arA1['h4] = 1'sbx;
					arA23['h4] = 1'sbx;
				end
				default: begin
					arIll['h4] = 1'b1;
					arA1['h4] = 1'sbx;
					arA23['h4] = 1'sbx;
				end
			endcase
		else if (opcode[11:6] == 'h2a)
			(* full_case, parallel_case *)
			case (col)
				0: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h125;
					arA23['h4] = 1'sbx;
				end
				1: begin
					arIll['h4] = 1'b1;
					arA1['h4] = 1'sbx;
					arA23['h4] = 1'sbx;
				end
				2: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'hb;
					arA23['h4] = 'h3cb;
				end
				3: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'hf;
					arA23['h4] = 'h3cb;
				end
				4: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h179;
					arA23['h4] = 'h3cb;
				end
				5: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h1c6;
					arA23['h4] = 'h3cb;
				end
				6: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h1e7;
					arA23['h4] = 'h3cb;
				end
				7: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'he;
					arA23['h4] = 'h3cb;
				end
				8: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h1e6;
					arA23['h4] = 'h3cb;
				end
				9: begin
					arIll['h4] = 1'b1;
					arA1['h4] = 1'sbx;
					arA23['h4] = 1'sbx;
				end
				10: begin
					arIll['h4] = 1'b1;
					arA1['h4] = 1'sbx;
					arA23['h4] = 1'sbx;
				end
				11: begin
					arIll['h4] = 1'b1;
					arA1['h4] = 1'sbx;
					arA23['h4] = 1'sbx;
				end
				default: begin
					arIll['h4] = 1'b1;
					arA1['h4] = 1'sbx;
					arA23['h4] = 1'sbx;
				end
			endcase
		else if (opcode[11:6] == 'h2b)
			(* full_case, parallel_case *)
			case (col)
				0: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h345;
					arA23['h4] = 1'sbx;
				end
				1: begin
					arIll['h4] = 1'b1;
					arA1['h4] = 1'sbx;
					arA23['h4] = 1'sbx;
				end
				2: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h6;
					arA23['h4] = 'h343;
				end
				3: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h21c;
					arA23['h4] = 'h343;
				end
				4: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h103;
					arA23['h4] = 'h343;
				end
				5: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h1c2;
					arA23['h4] = 'h343;
				end
				6: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h1e3;
					arA23['h4] = 'h343;
				end
				7: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'ha;
					arA23['h4] = 'h343;
				end
				8: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h1e2;
					arA23['h4] = 'h343;
				end
				9: begin
					arIll['h4] = 1'b1;
					arA1['h4] = 1'sbx;
					arA23['h4] = 1'sbx;
				end
				10: begin
					arIll['h4] = 1'b1;
					arA1['h4] = 1'sbx;
					arA23['h4] = 1'sbx;
				end
				11: begin
					arIll['h4] = 1'b1;
					arA1['h4] = 1'sbx;
					arA23['h4] = 1'sbx;
				end
				default: begin
					arIll['h4] = 1'b1;
					arA1['h4] = 1'sbx;
					arA23['h4] = 1'sbx;
				end
			endcase
		else if ((opcode[11:6] & 'h3e) == 'h32)
			(* full_case, parallel_case *)
			case (col)
				0: begin
					arIll['h4] = 1'b1;
					arA1['h4] = 1'sbx;
					arA23['h4] = 1'sbx;
				end
				1: begin
					arIll['h4] = 1'b1;
					arA1['h4] = 1'sbx;
					arA23['h4] = 1'sbx;
				end
				2: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h127;
					arA23['h4] = 1'sbx;
				end
				3: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h123;
					arA23['h4] = 1'sbx;
				end
				4: begin
					arIll['h4] = 1'b1;
					arA1['h4] = 1'sbx;
					arA23['h4] = 1'sbx;
				end
				5: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h1fd;
					arA23['h4] = 1'sbx;
				end
				6: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h1f5;
					arA23['h4] = 1'sbx;
				end
				7: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h1f9;
					arA23['h4] = 1'sbx;
				end
				8: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h1e9;
					arA23['h4] = 1'sbx;
				end
				9: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h1fd;
					arA23['h4] = 1'sbx;
				end
				10: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h1f5;
					arA23['h4] = 1'sbx;
				end
				11: begin
					arIll['h4] = 1'b1;
					arA1['h4] = 1'sbx;
					arA23['h4] = 1'sbx;
				end
				default: begin
					arIll['h4] = 1'b1;
					arA1['h4] = 1'sbx;
					arA23['h4] = 1'sbx;
				end
			endcase
		else if ((opcode[11:6] & 'h7) == 'h6)
			(* full_case, parallel_case *)
			case (col)
				0: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h152;
					arA23['h4] = 1'sbx;
				end
				1: begin
					arIll['h4] = 1'b1;
					arA1['h4] = 1'sbx;
					arA23['h4] = 1'sbx;
				end
				2: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h6;
					arA23['h4] = 'h151;
				end
				3: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h21c;
					arA23['h4] = 'h151;
				end
				4: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h103;
					arA23['h4] = 'h151;
				end
				5: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h1c2;
					arA23['h4] = 'h151;
				end
				6: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h1e3;
					arA23['h4] = 'h151;
				end
				7: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'ha;
					arA23['h4] = 'h151;
				end
				8: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h1e2;
					arA23['h4] = 'h151;
				end
				9: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h1c2;
					arA23['h4] = 'h151;
				end
				10: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h1e3;
					arA23['h4] = 'h151;
				end
				11: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'hea;
					arA23['h4] = 'h152;
				end
				default: begin
					arIll['h4] = 1'b1;
					arA1['h4] = 1'sbx;
					arA23['h4] = 1'sbx;
				end
			endcase
		else if ((opcode[11:6] & 'h7) == 'h7)
			(* full_case, parallel_case *)
			case (col)
				0: begin
					arIll['h4] = 1'b1;
					arA1['h4] = 1'sbx;
					arA23['h4] = 1'sbx;
				end
				1: begin
					arIll['h4] = 1'b1;
					arA1['h4] = 1'sbx;
					arA23['h4] = 1'sbx;
				end
				2: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h2f1;
					arA23['h4] = 1'sbx;
				end
				3: begin
					arIll['h4] = 1'b1;
					arA1['h4] = 1'sbx;
					arA23['h4] = 1'sbx;
				end
				4: begin
					arIll['h4] = 1'b1;
					arA1['h4] = 1'sbx;
					arA23['h4] = 1'sbx;
				end
				5: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h2f2;
					arA23['h4] = 1'sbx;
				end
				6: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h1fb;
					arA23['h4] = 1'sbx;
				end
				7: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h275;
					arA23['h4] = 1'sbx;
				end
				8: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h3e4;
					arA23['h4] = 1'sbx;
				end
				9: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h2f2;
					arA23['h4] = 1'sbx;
				end
				10: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h1fb;
					arA23['h4] = 1'sbx;
				end
				11: begin
					arIll['h4] = 1'b1;
					arA1['h4] = 1'sbx;
					arA23['h4] = 1'sbx;
				end
				default: begin
					arIll['h4] = 1'b1;
					arA1['h4] = 1'sbx;
					arA23['h4] = 1'sbx;
				end
			endcase
		else if (opcode[11:6] == 'h3a)
			(* full_case, parallel_case *)
			case (col)
				0: begin
					arIll['h4] = 1'b1;
					arA1['h4] = 1'sbx;
					arA23['h4] = 1'sbx;
				end
				1: begin
					arIll['h4] = 1'b1;
					arA1['h4] = 1'sbx;
					arA23['h4] = 1'sbx;
				end
				2: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h273;
					arA23['h4] = 1'sbx;
				end
				3: begin
					arIll['h4] = 1'b1;
					arA1['h4] = 1'sbx;
					arA23['h4] = 1'sbx;
				end
				4: begin
					arIll['h4] = 1'b1;
					arA1['h4] = 1'sbx;
					arA23['h4] = 1'sbx;
				end
				5: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h2b0;
					arA23['h4] = 1'sbx;
				end
				6: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h1f3;
					arA23['h4] = 1'sbx;
				end
				7: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h293;
					arA23['h4] = 1'sbx;
				end
				8: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h1f2;
					arA23['h4] = 1'sbx;
				end
				9: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h2b0;
					arA23['h4] = 1'sbx;
				end
				10: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h1f3;
					arA23['h4] = 1'sbx;
				end
				11: begin
					arIll['h4] = 1'b1;
					arA1['h4] = 1'sbx;
					arA23['h4] = 1'sbx;
				end
				default: begin
					arIll['h4] = 1'b1;
					arA1['h4] = 1'sbx;
					arA23['h4] = 1'sbx;
				end
			endcase
		else if (opcode[11:6] == 'h3b)
			(* full_case, parallel_case *)
			case (col)
				0: begin
					arIll['h4] = 1'b1;
					arA1['h4] = 1'sbx;
					arA23['h4] = 1'sbx;
				end
				1: begin
					arIll['h4] = 1'b1;
					arA1['h4] = 1'sbx;
					arA23['h4] = 1'sbx;
				end
				2: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h255;
					arA23['h4] = 1'sbx;
				end
				3: begin
					arIll['h4] = 1'b1;
					arA1['h4] = 1'sbx;
					arA23['h4] = 1'sbx;
				end
				4: begin
					arIll['h4] = 1'b1;
					arA1['h4] = 1'sbx;
					arA23['h4] = 1'sbx;
				end
				5: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h2b4;
					arA23['h4] = 1'sbx;
				end
				6: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h1f7;
					arA23['h4] = 1'sbx;
				end
				7: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h297;
					arA23['h4] = 1'sbx;
				end
				8: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h1f6;
					arA23['h4] = 1'sbx;
				end
				9: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h2b4;
					arA23['h4] = 1'sbx;
				end
				10: begin
					arIll['h4] = 1'b0;
					arA1['h4] = 'h1f7;
					arA23['h4] = 1'sbx;
				end
				11: begin
					arIll['h4] = 1'b1;
					arA1['h4] = 1'sbx;
					arA23['h4] = 1'sbx;
				end
				default: begin
					arIll['h4] = 1'b1;
					arA1['h4] = 1'sbx;
					arA23['h4] = 1'sbx;
				end
			endcase
		else if (opcode[11:6] == 'h39) begin
			arIll['h4] = illMisc;
			arA1['h4] = a1Misc;
			arA23['h4] = 1'sbx;
		end
		else begin
			arIll['h4] = 1'b1;
			arA1['h4] = 1'sbx;
			arA23['h4] = 1'sbx;
		end
	end
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (movEa)
			0:
				(* full_case, parallel_case *)
				case (col)
					0: begin
						arIll['h1] = 1'b0;
						arA1['h1] = 'h121;
						arA23['h1] = 1'sbx;
					end
					1: begin
						arIll['h1] = 1'b1;
						arA1['h1] = 1'sbx;
						arA23['h1] = 1'sbx;
					end
					2: begin
						arIll['h1] = 1'b0;
						arA1['h1] = 'h6;
						arA23['h1] = 'h29b;
					end
					3: begin
						arIll['h1] = 1'b0;
						arA1['h1] = 'h21c;
						arA23['h1] = 'h29b;
					end
					4: begin
						arIll['h1] = 1'b0;
						arA1['h1] = 'h103;
						arA23['h1] = 'h29b;
					end
					5: begin
						arIll['h1] = 1'b0;
						arA1['h1] = 'h1c2;
						arA23['h1] = 'h29b;
					end
					6: begin
						arIll['h1] = 1'b0;
						arA1['h1] = 'h1e3;
						arA23['h1] = 'h29b;
					end
					7: begin
						arIll['h1] = 1'b0;
						arA1['h1] = 'ha;
						arA23['h1] = 'h29b;
					end
					8: begin
						arIll['h1] = 1'b0;
						arA1['h1] = 'h1e2;
						arA23['h1] = 'h29b;
					end
					9: begin
						arIll['h1] = 1'b0;
						arA1['h1] = 'h1c2;
						arA23['h1] = 'h29b;
					end
					10: begin
						arIll['h1] = 1'b0;
						arA1['h1] = 'h1e3;
						arA23['h1] = 'h29b;
					end
					11: begin
						arIll['h1] = 1'b0;
						arA1['h1] = 'hea;
						arA23['h1] = 'h121;
					end
					default: begin
						arIll['h1] = 1'b1;
						arA1['h1] = 1'sbx;
						arA23['h1] = 1'sbx;
					end
				endcase
			2:
				(* full_case, parallel_case *)
				case (col)
					0: begin
						arIll['h1] = 1'b0;
						arA1['h1] = 'h2fa;
						arA23['h1] = 1'sbx;
					end
					1: begin
						arIll['h1] = 1'b1;
						arA1['h1] = 1'sbx;
						arA23['h1] = 1'sbx;
					end
					2: begin
						arIll['h1] = 1'b0;
						arA1['h1] = 'h6;
						arA23['h1] = 'h3ab;
					end
					3: begin
						arIll['h1] = 1'b0;
						arA1['h1] = 'h21c;
						arA23['h1] = 'h3ab;
					end
					4: begin
						arIll['h1] = 1'b0;
						arA1['h1] = 'h103;
						arA23['h1] = 'h3ab;
					end
					5: begin
						arIll['h1] = 1'b0;
						arA1['h1] = 'h1c2;
						arA23['h1] = 'h3ab;
					end
					6: begin
						arIll['h1] = 1'b0;
						arA1['h1] = 'h1e3;
						arA23['h1] = 'h3ab;
					end
					7: begin
						arIll['h1] = 1'b0;
						arA1['h1] = 'ha;
						arA23['h1] = 'h3ab;
					end
					8: begin
						arIll['h1] = 1'b0;
						arA1['h1] = 'h1e2;
						arA23['h1] = 'h3ab;
					end
					9: begin
						arIll['h1] = 1'b0;
						arA1['h1] = 'h1c2;
						arA23['h1] = 'h3ab;
					end
					10: begin
						arIll['h1] = 1'b0;
						arA1['h1] = 'h1e3;
						arA23['h1] = 'h3ab;
					end
					11: begin
						arIll['h1] = 1'b0;
						arA1['h1] = 'hea;
						arA23['h1] = 'h2fa;
					end
					default: begin
						arIll['h1] = 1'b1;
						arA1['h1] = 1'sbx;
						arA23['h1] = 1'sbx;
					end
				endcase
			3:
				(* full_case, parallel_case *)
				case (col)
					0: begin
						arIll['h1] = 1'b0;
						arA1['h1] = 'h2fe;
						arA23['h1] = 1'sbx;
					end
					1: begin
						arIll['h1] = 1'b1;
						arA1['h1] = 1'sbx;
						arA23['h1] = 1'sbx;
					end
					2: begin
						arIll['h1] = 1'b0;
						arA1['h1] = 'h6;
						arA23['h1] = 'h3af;
					end
					3: begin
						arIll['h1] = 1'b0;
						arA1['h1] = 'h21c;
						arA23['h1] = 'h3af;
					end
					4: begin
						arIll['h1] = 1'b0;
						arA1['h1] = 'h103;
						arA23['h1] = 'h3af;
					end
					5: begin
						arIll['h1] = 1'b0;
						arA1['h1] = 'h1c2;
						arA23['h1] = 'h3af;
					end
					6: begin
						arIll['h1] = 1'b0;
						arA1['h1] = 'h1e3;
						arA23['h1] = 'h3af;
					end
					7: begin
						arIll['h1] = 1'b0;
						arA1['h1] = 'ha;
						arA23['h1] = 'h3af;
					end
					8: begin
						arIll['h1] = 1'b0;
						arA1['h1] = 'h1e2;
						arA23['h1] = 'h3af;
					end
					9: begin
						arIll['h1] = 1'b0;
						arA1['h1] = 'h1c2;
						arA23['h1] = 'h3af;
					end
					10: begin
						arIll['h1] = 1'b0;
						arA1['h1] = 'h1e3;
						arA23['h1] = 'h3af;
					end
					11: begin
						arIll['h1] = 1'b0;
						arA1['h1] = 'hea;
						arA23['h1] = 'h2fe;
					end
					default: begin
						arIll['h1] = 1'b1;
						arA1['h1] = 1'sbx;
						arA23['h1] = 1'sbx;
					end
				endcase
			4:
				(* full_case, parallel_case *)
				case (col)
					0: begin
						arIll['h1] = 1'b0;
						arA1['h1] = 'h2f8;
						arA23['h1] = 1'sbx;
					end
					1: begin
						arIll['h1] = 1'b1;
						arA1['h1] = 1'sbx;
						arA23['h1] = 1'sbx;
					end
					2: begin
						arIll['h1] = 1'b0;
						arA1['h1] = 'h6;
						arA23['h1] = 'h38b;
					end
					3: begin
						arIll['h1] = 1'b0;
						arA1['h1] = 'h21c;
						arA23['h1] = 'h38b;
					end
					4: begin
						arIll['h1] = 1'b0;
						arA1['h1] = 'h103;
						arA23['h1] = 'h38b;
					end
					5: begin
						arIll['h1] = 1'b0;
						arA1['h1] = 'h1c2;
						arA23['h1] = 'h38b;
					end
					6: begin
						arIll['h1] = 1'b0;
						arA1['h1] = 'h1e3;
						arA23['h1] = 'h38b;
					end
					7: begin
						arIll['h1] = 1'b0;
						arA1['h1] = 'ha;
						arA23['h1] = 'h38b;
					end
					8: begin
						arIll['h1] = 1'b0;
						arA1['h1] = 'h1e2;
						arA23['h1] = 'h38b;
					end
					9: begin
						arIll['h1] = 1'b0;
						arA1['h1] = 'h1c2;
						arA23['h1] = 'h38b;
					end
					10: begin
						arIll['h1] = 1'b0;
						arA1['h1] = 'h1e3;
						arA23['h1] = 'h38b;
					end
					11: begin
						arIll['h1] = 1'b0;
						arA1['h1] = 'hea;
						arA23['h1] = 'h2f8;
					end
					default: begin
						arIll['h1] = 1'b1;
						arA1['h1] = 1'sbx;
						arA23['h1] = 1'sbx;
					end
				endcase
			5:
				(* full_case, parallel_case *)
				case (col)
					0: begin
						arIll['h1] = 1'b0;
						arA1['h1] = 'h2da;
						arA23['h1] = 1'sbx;
					end
					1: begin
						arIll['h1] = 1'b1;
						arA1['h1] = 1'sbx;
						arA23['h1] = 1'sbx;
					end
					2: begin
						arIll['h1] = 1'b0;
						arA1['h1] = 'h6;
						arA23['h1] = 'h38a;
					end
					3: begin
						arIll['h1] = 1'b0;
						arA1['h1] = 'h21c;
						arA23['h1] = 'h38a;
					end
					4: begin
						arIll['h1] = 1'b0;
						arA1['h1] = 'h103;
						arA23['h1] = 'h38a;
					end
					5: begin
						arIll['h1] = 1'b0;
						arA1['h1] = 'h1c2;
						arA23['h1] = 'h38a;
					end
					6: begin
						arIll['h1] = 1'b0;
						arA1['h1] = 'h1e3;
						arA23['h1] = 'h38a;
					end
					7: begin
						arIll['h1] = 1'b0;
						arA1['h1] = 'ha;
						arA23['h1] = 'h38a;
					end
					8: begin
						arIll['h1] = 1'b0;
						arA1['h1] = 'h1e2;
						arA23['h1] = 'h38a;
					end
					9: begin
						arIll['h1] = 1'b0;
						arA1['h1] = 'h1c2;
						arA23['h1] = 'h38a;
					end
					10: begin
						arIll['h1] = 1'b0;
						arA1['h1] = 'h1e3;
						arA23['h1] = 'h38a;
					end
					11: begin
						arIll['h1] = 1'b0;
						arA1['h1] = 'hea;
						arA23['h1] = 'h2da;
					end
					default: begin
						arIll['h1] = 1'b1;
						arA1['h1] = 1'sbx;
						arA23['h1] = 1'sbx;
					end
				endcase
			6:
				(* full_case, parallel_case *)
				case (col)
					0: begin
						arIll['h1] = 1'b0;
						arA1['h1] = 'h1eb;
						arA23['h1] = 1'sbx;
					end
					1: begin
						arIll['h1] = 1'b1;
						arA1['h1] = 1'sbx;
						arA23['h1] = 1'sbx;
					end
					2: begin
						arIll['h1] = 1'b0;
						arA1['h1] = 'h6;
						arA23['h1] = 'h298;
					end
					3: begin
						arIll['h1] = 1'b0;
						arA1['h1] = 'h21c;
						arA23['h1] = 'h298;
					end
					4: begin
						arIll['h1] = 1'b0;
						arA1['h1] = 'h103;
						arA23['h1] = 'h298;
					end
					5: begin
						arIll['h1] = 1'b0;
						arA1['h1] = 'h1c2;
						arA23['h1] = 'h298;
					end
					6: begin
						arIll['h1] = 1'b0;
						arA1['h1] = 'h1e3;
						arA23['h1] = 'h298;
					end
					7: begin
						arIll['h1] = 1'b0;
						arA1['h1] = 'ha;
						arA23['h1] = 'h298;
					end
					8: begin
						arIll['h1] = 1'b0;
						arA1['h1] = 'h1e2;
						arA23['h1] = 'h298;
					end
					9: begin
						arIll['h1] = 1'b0;
						arA1['h1] = 'h1c2;
						arA23['h1] = 'h298;
					end
					10: begin
						arIll['h1] = 1'b0;
						arA1['h1] = 'h1e3;
						arA23['h1] = 'h298;
					end
					11: begin
						arIll['h1] = 1'b0;
						arA1['h1] = 'hea;
						arA23['h1] = 'h1eb;
					end
					default: begin
						arIll['h1] = 1'b1;
						arA1['h1] = 1'sbx;
						arA23['h1] = 1'sbx;
					end
				endcase
			7:
				(* full_case, parallel_case *)
				case (col)
					0: begin
						arIll['h1] = 1'b0;
						arA1['h1] = 'h2d9;
						arA23['h1] = 1'sbx;
					end
					1: begin
						arIll['h1] = 1'b1;
						arA1['h1] = 1'sbx;
						arA23['h1] = 1'sbx;
					end
					2: begin
						arIll['h1] = 1'b0;
						arA1['h1] = 'h6;
						arA23['h1] = 'h388;
					end
					3: begin
						arIll['h1] = 1'b0;
						arA1['h1] = 'h21c;
						arA23['h1] = 'h388;
					end
					4: begin
						arIll['h1] = 1'b0;
						arA1['h1] = 'h103;
						arA23['h1] = 'h388;
					end
					5: begin
						arIll['h1] = 1'b0;
						arA1['h1] = 'h1c2;
						arA23['h1] = 'h388;
					end
					6: begin
						arIll['h1] = 1'b0;
						arA1['h1] = 'h1e3;
						arA23['h1] = 'h388;
					end
					7: begin
						arIll['h1] = 1'b0;
						arA1['h1] = 'ha;
						arA23['h1] = 'h388;
					end
					8: begin
						arIll['h1] = 1'b0;
						arA1['h1] = 'h1e2;
						arA23['h1] = 'h388;
					end
					9: begin
						arIll['h1] = 1'b0;
						arA1['h1] = 'h1c2;
						arA23['h1] = 'h388;
					end
					10: begin
						arIll['h1] = 1'b0;
						arA1['h1] = 'h1e3;
						arA23['h1] = 'h388;
					end
					11: begin
						arIll['h1] = 1'b0;
						arA1['h1] = 'hea;
						arA23['h1] = 'h2d9;
					end
					default: begin
						arIll['h1] = 1'b1;
						arA1['h1] = 1'sbx;
						arA23['h1] = 1'sbx;
					end
				endcase
			8:
				(* full_case, parallel_case *)
				case (col)
					0: begin
						arIll['h1] = 1'b0;
						arA1['h1] = 'h1ea;
						arA23['h1] = 1'sbx;
					end
					1: begin
						arIll['h1] = 1'b1;
						arA1['h1] = 1'sbx;
						arA23['h1] = 1'sbx;
					end
					2: begin
						arIll['h1] = 1'b0;
						arA1['h1] = 'h6;
						arA23['h1] = 'h32b;
					end
					3: begin
						arIll['h1] = 1'b0;
						arA1['h1] = 'h21c;
						arA23['h1] = 'h32b;
					end
					4: begin
						arIll['h1] = 1'b0;
						arA1['h1] = 'h103;
						arA23['h1] = 'h32b;
					end
					5: begin
						arIll['h1] = 1'b0;
						arA1['h1] = 'h1c2;
						arA23['h1] = 'h32b;
					end
					6: begin
						arIll['h1] = 1'b0;
						arA1['h1] = 'h1e3;
						arA23['h1] = 'h32b;
					end
					7: begin
						arIll['h1] = 1'b0;
						arA1['h1] = 'ha;
						arA23['h1] = 'h32b;
					end
					8: begin
						arIll['h1] = 1'b0;
						arA1['h1] = 'h1e2;
						arA23['h1] = 'h32b;
					end
					9: begin
						arIll['h1] = 1'b0;
						arA1['h1] = 'h1c2;
						arA23['h1] = 'h32b;
					end
					10: begin
						arIll['h1] = 1'b0;
						arA1['h1] = 'h1e3;
						arA23['h1] = 'h32b;
					end
					11: begin
						arIll['h1] = 1'b0;
						arA1['h1] = 'hea;
						arA23['h1] = 'h1ea;
					end
					default: begin
						arIll['h1] = 1'b1;
						arA1['h1] = 1'sbx;
						arA23['h1] = 1'sbx;
					end
				endcase
			default: begin
				arIll['h1] = 1'b1;
				arA1['h1] = 1'sbx;
				arA23['h1] = 1'sbx;
			end
		endcase
		(* full_case, parallel_case *)
		case (movEa)
			0:
				(* full_case, parallel_case *)
				case (col)
					0: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'h129;
						arA23['h2] = 1'sbx;
					end
					1: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'h129;
						arA23['h2] = 1'sbx;
					end
					2: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'hb;
						arA23['h2] = 'h29f;
					end
					3: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'hf;
						arA23['h2] = 'h29f;
					end
					4: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'h179;
						arA23['h2] = 'h29f;
					end
					5: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'h1c6;
						arA23['h2] = 'h29f;
					end
					6: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'h1e7;
						arA23['h2] = 'h29f;
					end
					7: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'he;
						arA23['h2] = 'h29f;
					end
					8: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'h1e6;
						arA23['h2] = 'h29f;
					end
					9: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'h1c6;
						arA23['h2] = 'h29f;
					end
					10: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'h1e7;
						arA23['h2] = 'h29f;
					end
					11: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'ha7;
						arA23['h2] = 'h129;
					end
					default: begin
						arIll['h2] = 1'b1;
						arA1['h2] = 1'sbx;
						arA23['h2] = 1'sbx;
					end
				endcase
			1:
				(* full_case, parallel_case *)
				case (col)
					0: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'h129;
						arA23['h2] = 1'sbx;
					end
					1: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'h129;
						arA23['h2] = 1'sbx;
					end
					2: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'hb;
						arA23['h2] = 'h29f;
					end
					3: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'hf;
						arA23['h2] = 'h29f;
					end
					4: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'h179;
						arA23['h2] = 'h29f;
					end
					5: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'h1c6;
						arA23['h2] = 'h29f;
					end
					6: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'h1e7;
						arA23['h2] = 'h29f;
					end
					7: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'he;
						arA23['h2] = 'h29f;
					end
					8: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'h1e6;
						arA23['h2] = 'h29f;
					end
					9: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'h1c6;
						arA23['h2] = 'h29f;
					end
					10: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'h1e7;
						arA23['h2] = 'h29f;
					end
					11: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'ha7;
						arA23['h2] = 'h129;
					end
					default: begin
						arIll['h2] = 1'b1;
						arA1['h2] = 1'sbx;
						arA23['h2] = 1'sbx;
					end
				endcase
			2:
				(* full_case, parallel_case *)
				case (col)
					0: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'h2f9;
						arA23['h2] = 1'sbx;
					end
					1: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'h2f9;
						arA23['h2] = 1'sbx;
					end
					2: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'hb;
						arA23['h2] = 'h3a9;
					end
					3: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'hf;
						arA23['h2] = 'h3a9;
					end
					4: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'h179;
						arA23['h2] = 'h3a9;
					end
					5: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'h1c6;
						arA23['h2] = 'h3a9;
					end
					6: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'h1e7;
						arA23['h2] = 'h3a9;
					end
					7: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'he;
						arA23['h2] = 'h3a9;
					end
					8: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'h1e6;
						arA23['h2] = 'h3a9;
					end
					9: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'h1c6;
						arA23['h2] = 'h3a9;
					end
					10: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'h1e7;
						arA23['h2] = 'h3a9;
					end
					11: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'ha7;
						arA23['h2] = 'h2f9;
					end
					default: begin
						arIll['h2] = 1'b1;
						arA1['h2] = 1'sbx;
						arA23['h2] = 1'sbx;
					end
				endcase
			3:
				(* full_case, parallel_case *)
				case (col)
					0: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'h2fd;
						arA23['h2] = 1'sbx;
					end
					1: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'h2fd;
						arA23['h2] = 1'sbx;
					end
					2: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'hb;
						arA23['h2] = 'h3ad;
					end
					3: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'hf;
						arA23['h2] = 'h3ad;
					end
					4: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'h179;
						arA23['h2] = 'h3ad;
					end
					5: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'h1c6;
						arA23['h2] = 'h3ad;
					end
					6: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'h1e7;
						arA23['h2] = 'h3ad;
					end
					7: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'he;
						arA23['h2] = 'h3ad;
					end
					8: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'h1e6;
						arA23['h2] = 'h3ad;
					end
					9: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'h1c6;
						arA23['h2] = 'h3ad;
					end
					10: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'h1e7;
						arA23['h2] = 'h3ad;
					end
					11: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'ha7;
						arA23['h2] = 'h2fd;
					end
					default: begin
						arIll['h2] = 1'b1;
						arA1['h2] = 1'sbx;
						arA23['h2] = 1'sbx;
					end
				endcase
			4:
				(* full_case, parallel_case *)
				case (col)
					0: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'h2fc;
						arA23['h2] = 1'sbx;
					end
					1: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'h2fc;
						arA23['h2] = 1'sbx;
					end
					2: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'hb;
						arA23['h2] = 'h38f;
					end
					3: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'hf;
						arA23['h2] = 'h38f;
					end
					4: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'h179;
						arA23['h2] = 'h38f;
					end
					5: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'h1c6;
						arA23['h2] = 'h38f;
					end
					6: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'h1e7;
						arA23['h2] = 'h38f;
					end
					7: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'he;
						arA23['h2] = 'h38f;
					end
					8: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'h1e6;
						arA23['h2] = 'h38f;
					end
					9: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'h1c6;
						arA23['h2] = 'h38f;
					end
					10: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'h1e7;
						arA23['h2] = 'h38f;
					end
					11: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'ha7;
						arA23['h2] = 'h2fc;
					end
					default: begin
						arIll['h2] = 1'b1;
						arA1['h2] = 1'sbx;
						arA23['h2] = 1'sbx;
					end
				endcase
			5:
				(* full_case, parallel_case *)
				case (col)
					0: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'h2de;
						arA23['h2] = 1'sbx;
					end
					1: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'h2de;
						arA23['h2] = 1'sbx;
					end
					2: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'hb;
						arA23['h2] = 'h38e;
					end
					3: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'hf;
						arA23['h2] = 'h38e;
					end
					4: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'h179;
						arA23['h2] = 'h38e;
					end
					5: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'h1c6;
						arA23['h2] = 'h38e;
					end
					6: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'h1e7;
						arA23['h2] = 'h38e;
					end
					7: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'he;
						arA23['h2] = 'h38e;
					end
					8: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'h1e6;
						arA23['h2] = 'h38e;
					end
					9: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'h1c6;
						arA23['h2] = 'h38e;
					end
					10: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'h1e7;
						arA23['h2] = 'h38e;
					end
					11: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'ha7;
						arA23['h2] = 'h2de;
					end
					default: begin
						arIll['h2] = 1'b1;
						arA1['h2] = 1'sbx;
						arA23['h2] = 1'sbx;
					end
				endcase
			6:
				(* full_case, parallel_case *)
				case (col)
					0: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'h1ef;
						arA23['h2] = 1'sbx;
					end
					1: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'h1ef;
						arA23['h2] = 1'sbx;
					end
					2: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'hb;
						arA23['h2] = 'h29c;
					end
					3: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'hf;
						arA23['h2] = 'h29c;
					end
					4: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'h179;
						arA23['h2] = 'h29c;
					end
					5: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'h1c6;
						arA23['h2] = 'h29c;
					end
					6: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'h1e7;
						arA23['h2] = 'h29c;
					end
					7: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'he;
						arA23['h2] = 'h29c;
					end
					8: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'h1e6;
						arA23['h2] = 'h29c;
					end
					9: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'h1c6;
						arA23['h2] = 'h29c;
					end
					10: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'h1e7;
						arA23['h2] = 'h29c;
					end
					11: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'ha7;
						arA23['h2] = 'h1ef;
					end
					default: begin
						arIll['h2] = 1'b1;
						arA1['h2] = 1'sbx;
						arA23['h2] = 1'sbx;
					end
				endcase
			7:
				(* full_case, parallel_case *)
				case (col)
					0: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'h2dd;
						arA23['h2] = 1'sbx;
					end
					1: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'h2dd;
						arA23['h2] = 1'sbx;
					end
					2: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'hb;
						arA23['h2] = 'h38c;
					end
					3: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'hf;
						arA23['h2] = 'h38c;
					end
					4: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'h179;
						arA23['h2] = 'h38c;
					end
					5: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'h1c6;
						arA23['h2] = 'h38c;
					end
					6: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'h1e7;
						arA23['h2] = 'h38c;
					end
					7: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'he;
						arA23['h2] = 'h38c;
					end
					8: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'h1e6;
						arA23['h2] = 'h38c;
					end
					9: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'h1c6;
						arA23['h2] = 'h38c;
					end
					10: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'h1e7;
						arA23['h2] = 'h38c;
					end
					11: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'ha7;
						arA23['h2] = 'h2dd;
					end
					default: begin
						arIll['h2] = 1'b1;
						arA1['h2] = 1'sbx;
						arA23['h2] = 1'sbx;
					end
				endcase
			8:
				(* full_case, parallel_case *)
				case (col)
					0: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'h1ee;
						arA23['h2] = 1'sbx;
					end
					1: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'h1ee;
						arA23['h2] = 1'sbx;
					end
					2: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'hb;
						arA23['h2] = 'h30f;
					end
					3: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'hf;
						arA23['h2] = 'h30f;
					end
					4: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'h179;
						arA23['h2] = 'h30f;
					end
					5: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'h1c6;
						arA23['h2] = 'h30f;
					end
					6: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'h1e7;
						arA23['h2] = 'h30f;
					end
					7: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'he;
						arA23['h2] = 'h30f;
					end
					8: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'h1e6;
						arA23['h2] = 'h30f;
					end
					9: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'h1c6;
						arA23['h2] = 'h30f;
					end
					10: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'h1e7;
						arA23['h2] = 'h30f;
					end
					11: begin
						arIll['h2] = 1'b0;
						arA1['h2] = 'ha7;
						arA23['h2] = 'h1ee;
					end
					default: begin
						arIll['h2] = 1'b1;
						arA1['h2] = 1'sbx;
						arA23['h2] = 1'sbx;
					end
				endcase
			default: begin
				arIll['h2] = 1'b1;
				arA1['h2] = 1'sbx;
				arA23['h2] = 1'sbx;
			end
		endcase
		(* full_case, parallel_case *)
		case (movEa)
			0:
				(* full_case, parallel_case *)
				case (col)
					0: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'h121;
						arA23['h3] = 1'sbx;
					end
					1: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'h121;
						arA23['h3] = 1'sbx;
					end
					2: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'h6;
						arA23['h3] = 'h29b;
					end
					3: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'h21c;
						arA23['h3] = 'h29b;
					end
					4: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'h103;
						arA23['h3] = 'h29b;
					end
					5: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'h1c2;
						arA23['h3] = 'h29b;
					end
					6: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'h1e3;
						arA23['h3] = 'h29b;
					end
					7: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'ha;
						arA23['h3] = 'h29b;
					end
					8: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'h1e2;
						arA23['h3] = 'h29b;
					end
					9: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'h1c2;
						arA23['h3] = 'h29b;
					end
					10: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'h1e3;
						arA23['h3] = 'h29b;
					end
					11: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'hea;
						arA23['h3] = 'h121;
					end
					default: begin
						arIll['h3] = 1'b1;
						arA1['h3] = 1'sbx;
						arA23['h3] = 1'sbx;
					end
				endcase
			1:
				(* full_case, parallel_case *)
				case (col)
					0: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'h279;
						arA23['h3] = 1'sbx;
					end
					1: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'h279;
						arA23['h3] = 1'sbx;
					end
					2: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'h6;
						arA23['h3] = 'h158;
					end
					3: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'h21c;
						arA23['h3] = 'h158;
					end
					4: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'h103;
						arA23['h3] = 'h158;
					end
					5: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'h1c2;
						arA23['h3] = 'h158;
					end
					6: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'h1e3;
						arA23['h3] = 'h158;
					end
					7: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'ha;
						arA23['h3] = 'h158;
					end
					8: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'h1e2;
						arA23['h3] = 'h158;
					end
					9: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'h1c2;
						arA23['h3] = 'h158;
					end
					10: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'h1e3;
						arA23['h3] = 'h158;
					end
					11: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'hea;
						arA23['h3] = 'h279;
					end
					default: begin
						arIll['h3] = 1'b1;
						arA1['h3] = 1'sbx;
						arA23['h3] = 1'sbx;
					end
				endcase
			2:
				(* full_case, parallel_case *)
				case (col)
					0: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'h2fa;
						arA23['h3] = 1'sbx;
					end
					1: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'h2fa;
						arA23['h3] = 1'sbx;
					end
					2: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'h6;
						arA23['h3] = 'h3ab;
					end
					3: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'h21c;
						arA23['h3] = 'h3ab;
					end
					4: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'h103;
						arA23['h3] = 'h3ab;
					end
					5: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'h1c2;
						arA23['h3] = 'h3ab;
					end
					6: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'h1e3;
						arA23['h3] = 'h3ab;
					end
					7: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'ha;
						arA23['h3] = 'h3ab;
					end
					8: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'h1e2;
						arA23['h3] = 'h3ab;
					end
					9: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'h1c2;
						arA23['h3] = 'h3ab;
					end
					10: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'h1e3;
						arA23['h3] = 'h3ab;
					end
					11: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'hea;
						arA23['h3] = 'h2fa;
					end
					default: begin
						arIll['h3] = 1'b1;
						arA1['h3] = 1'sbx;
						arA23['h3] = 1'sbx;
					end
				endcase
			3:
				(* full_case, parallel_case *)
				case (col)
					0: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'h2fe;
						arA23['h3] = 1'sbx;
					end
					1: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'h2fe;
						arA23['h3] = 1'sbx;
					end
					2: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'h6;
						arA23['h3] = 'h3af;
					end
					3: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'h21c;
						arA23['h3] = 'h3af;
					end
					4: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'h103;
						arA23['h3] = 'h3af;
					end
					5: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'h1c2;
						arA23['h3] = 'h3af;
					end
					6: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'h1e3;
						arA23['h3] = 'h3af;
					end
					7: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'ha;
						arA23['h3] = 'h3af;
					end
					8: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'h1e2;
						arA23['h3] = 'h3af;
					end
					9: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'h1c2;
						arA23['h3] = 'h3af;
					end
					10: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'h1e3;
						arA23['h3] = 'h3af;
					end
					11: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'hea;
						arA23['h3] = 'h2fe;
					end
					default: begin
						arIll['h3] = 1'b1;
						arA1['h3] = 1'sbx;
						arA23['h3] = 1'sbx;
					end
				endcase
			4:
				(* full_case, parallel_case *)
				case (col)
					0: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'h2f8;
						arA23['h3] = 1'sbx;
					end
					1: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'h2f8;
						arA23['h3] = 1'sbx;
					end
					2: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'h6;
						arA23['h3] = 'h38b;
					end
					3: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'h21c;
						arA23['h3] = 'h38b;
					end
					4: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'h103;
						arA23['h3] = 'h38b;
					end
					5: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'h1c2;
						arA23['h3] = 'h38b;
					end
					6: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'h1e3;
						arA23['h3] = 'h38b;
					end
					7: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'ha;
						arA23['h3] = 'h38b;
					end
					8: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'h1e2;
						arA23['h3] = 'h38b;
					end
					9: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'h1c2;
						arA23['h3] = 'h38b;
					end
					10: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'h1e3;
						arA23['h3] = 'h38b;
					end
					11: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'hea;
						arA23['h3] = 'h2f8;
					end
					default: begin
						arIll['h3] = 1'b1;
						arA1['h3] = 1'sbx;
						arA23['h3] = 1'sbx;
					end
				endcase
			5:
				(* full_case, parallel_case *)
				case (col)
					0: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'h2da;
						arA23['h3] = 1'sbx;
					end
					1: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'h2da;
						arA23['h3] = 1'sbx;
					end
					2: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'h6;
						arA23['h3] = 'h38a;
					end
					3: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'h21c;
						arA23['h3] = 'h38a;
					end
					4: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'h103;
						arA23['h3] = 'h38a;
					end
					5: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'h1c2;
						arA23['h3] = 'h38a;
					end
					6: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'h1e3;
						arA23['h3] = 'h38a;
					end
					7: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'ha;
						arA23['h3] = 'h38a;
					end
					8: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'h1e2;
						arA23['h3] = 'h38a;
					end
					9: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'h1c2;
						arA23['h3] = 'h38a;
					end
					10: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'h1e3;
						arA23['h3] = 'h38a;
					end
					11: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'hea;
						arA23['h3] = 'h2da;
					end
					default: begin
						arIll['h3] = 1'b1;
						arA1['h3] = 1'sbx;
						arA23['h3] = 1'sbx;
					end
				endcase
			6:
				(* full_case, parallel_case *)
				case (col)
					0: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'h1eb;
						arA23['h3] = 1'sbx;
					end
					1: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'h1eb;
						arA23['h3] = 1'sbx;
					end
					2: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'h6;
						arA23['h3] = 'h298;
					end
					3: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'h21c;
						arA23['h3] = 'h298;
					end
					4: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'h103;
						arA23['h3] = 'h298;
					end
					5: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'h1c2;
						arA23['h3] = 'h298;
					end
					6: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'h1e3;
						arA23['h3] = 'h298;
					end
					7: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'ha;
						arA23['h3] = 'h298;
					end
					8: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'h1e2;
						arA23['h3] = 'h298;
					end
					9: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'h1c2;
						arA23['h3] = 'h298;
					end
					10: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'h1e3;
						arA23['h3] = 'h298;
					end
					11: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'hea;
						arA23['h3] = 'h1eb;
					end
					default: begin
						arIll['h3] = 1'b1;
						arA1['h3] = 1'sbx;
						arA23['h3] = 1'sbx;
					end
				endcase
			7:
				(* full_case, parallel_case *)
				case (col)
					0: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'h2d9;
						arA23['h3] = 1'sbx;
					end
					1: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'h2d9;
						arA23['h3] = 1'sbx;
					end
					2: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'h6;
						arA23['h3] = 'h388;
					end
					3: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'h21c;
						arA23['h3] = 'h388;
					end
					4: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'h103;
						arA23['h3] = 'h388;
					end
					5: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'h1c2;
						arA23['h3] = 'h388;
					end
					6: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'h1e3;
						arA23['h3] = 'h388;
					end
					7: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'ha;
						arA23['h3] = 'h388;
					end
					8: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'h1e2;
						arA23['h3] = 'h388;
					end
					9: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'h1c2;
						arA23['h3] = 'h388;
					end
					10: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'h1e3;
						arA23['h3] = 'h388;
					end
					11: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'hea;
						arA23['h3] = 'h2d9;
					end
					default: begin
						arIll['h3] = 1'b1;
						arA1['h3] = 1'sbx;
						arA23['h3] = 1'sbx;
					end
				endcase
			8:
				(* full_case, parallel_case *)
				case (col)
					0: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'h1ea;
						arA23['h3] = 1'sbx;
					end
					1: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'h1ea;
						arA23['h3] = 1'sbx;
					end
					2: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'h6;
						arA23['h3] = 'h32b;
					end
					3: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'h21c;
						arA23['h3] = 'h32b;
					end
					4: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'h103;
						arA23['h3] = 'h32b;
					end
					5: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'h1c2;
						arA23['h3] = 'h32b;
					end
					6: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'h1e3;
						arA23['h3] = 'h32b;
					end
					7: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'ha;
						arA23['h3] = 'h32b;
					end
					8: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'h1e2;
						arA23['h3] = 'h32b;
					end
					9: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'h1c2;
						arA23['h3] = 'h32b;
					end
					10: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'h1e3;
						arA23['h3] = 'h32b;
					end
					11: begin
						arIll['h3] = 1'b0;
						arA1['h3] = 'hea;
						arA23['h3] = 'h1ea;
					end
					default: begin
						arIll['h3] = 1'b1;
						arA1['h3] = 1'sbx;
						arA23['h3] = 1'sbx;
					end
				endcase
			default: begin
				arIll['h3] = 1'b1;
				arA1['h3] = 1'sbx;
				arA23['h3] = 1'sbx;
			end
		endcase
		(* full_case, parallel_case *)
		case (row86)
			3'b000:
				(* full_case, parallel_case *)
				case (col)
					0: begin
						arIll['h5] = 1'b0;
						arA1['h5] = 'h2d8;
						arA23['h5] = 1'sbx;
					end
					1: begin
						arIll['h5] = 1'b1;
						arA1['h5] = 1'sbx;
						arA23['h5] = 1'sbx;
					end
					2: begin
						arIll['h5] = 1'b0;
						arA1['h5] = 'h6;
						arA23['h5] = 'h2f3;
					end
					3: begin
						arIll['h5] = 1'b0;
						arA1['h5] = 'h21c;
						arA23['h5] = 'h2f3;
					end
					4: begin
						arIll['h5] = 1'b0;
						arA1['h5] = 'h103;
						arA23['h5] = 'h2f3;
					end
					5: begin
						arIll['h5] = 1'b0;
						arA1['h5] = 'h1c2;
						arA23['h5] = 'h2f3;
					end
					6: begin
						arIll['h5] = 1'b0;
						arA1['h5] = 'h1e3;
						arA23['h5] = 'h2f3;
					end
					7: begin
						arIll['h5] = 1'b0;
						arA1['h5] = 'ha;
						arA23['h5] = 'h2f3;
					end
					8: begin
						arIll['h5] = 1'b0;
						arA1['h5] = 'h1e2;
						arA23['h5] = 'h2f3;
					end
					default: begin
						arIll['h5] = 1'b1;
						arA1['h5] = 1'sbx;
						arA23['h5] = 1'sbx;
					end
				endcase
			3'b001:
				(* full_case, parallel_case *)
				case (col)
					0: begin
						arIll['h5] = 1'b0;
						arA1['h5] = 'h2d8;
						arA23['h5] = 1'sbx;
					end
					1: begin
						arIll['h5] = 1'b0;
						arA1['h5] = 'h2dc;
						arA23['h5] = 1'sbx;
					end
					2: begin
						arIll['h5] = 1'b0;
						arA1['h5] = 'h6;
						arA23['h5] = 'h2f3;
					end
					3: begin
						arIll['h5] = 1'b0;
						arA1['h5] = 'h21c;
						arA23['h5] = 'h2f3;
					end
					4: begin
						arIll['h5] = 1'b0;
						arA1['h5] = 'h103;
						arA23['h5] = 'h2f3;
					end
					5: begin
						arIll['h5] = 1'b0;
						arA1['h5] = 'h1c2;
						arA23['h5] = 'h2f3;
					end
					6: begin
						arIll['h5] = 1'b0;
						arA1['h5] = 'h1e3;
						arA23['h5] = 'h2f3;
					end
					7: begin
						arIll['h5] = 1'b0;
						arA1['h5] = 'ha;
						arA23['h5] = 'h2f3;
					end
					8: begin
						arIll['h5] = 1'b0;
						arA1['h5] = 'h1e2;
						arA23['h5] = 'h2f3;
					end
					default: begin
						arIll['h5] = 1'b1;
						arA1['h5] = 1'sbx;
						arA23['h5] = 1'sbx;
					end
				endcase
			3'b010:
				(* full_case, parallel_case *)
				case (col)
					0: begin
						arIll['h5] = 1'b0;
						arA1['h5] = 'h2dc;
						arA23['h5] = 1'sbx;
					end
					1: begin
						arIll['h5] = 1'b0;
						arA1['h5] = 'h2dc;
						arA23['h5] = 1'sbx;
					end
					2: begin
						arIll['h5] = 1'b0;
						arA1['h5] = 'hb;
						arA23['h5] = 'h2f7;
					end
					3: begin
						arIll['h5] = 1'b0;
						arA1['h5] = 'hf;
						arA23['h5] = 'h2f7;
					end
					4: begin
						arIll['h5] = 1'b0;
						arA1['h5] = 'h179;
						arA23['h5] = 'h2f7;
					end
					5: begin
						arIll['h5] = 1'b0;
						arA1['h5] = 'h1c6;
						arA23['h5] = 'h2f7;
					end
					6: begin
						arIll['h5] = 1'b0;
						arA1['h5] = 'h1e7;
						arA23['h5] = 'h2f7;
					end
					7: begin
						arIll['h5] = 1'b0;
						arA1['h5] = 'he;
						arA23['h5] = 'h2f7;
					end
					8: begin
						arIll['h5] = 1'b0;
						arA1['h5] = 'h1e6;
						arA23['h5] = 'h2f7;
					end
					default: begin
						arIll['h5] = 1'b1;
						arA1['h5] = 1'sbx;
						arA23['h5] = 1'sbx;
					end
				endcase
			3'b011:
				(* full_case, parallel_case *)
				case (col)
					0: begin
						arIll['h5] = 1'b0;
						arA1['h5] = 'h384;
						arA23['h5] = 1'sbx;
					end
					1: begin
						arIll['h5] = 1'b0;
						arA1['h5] = 'h6c;
						arA23['h5] = 1'sbx;
					end
					2: begin
						arIll['h5] = 1'b0;
						arA1['h5] = 'h6;
						arA23['h5] = 'h380;
					end
					3: begin
						arIll['h5] = 1'b0;
						arA1['h5] = 'h21c;
						arA23['h5] = 'h380;
					end
					4: begin
						arIll['h5] = 1'b0;
						arA1['h5] = 'h103;
						arA23['h5] = 'h380;
					end
					5: begin
						arIll['h5] = 1'b0;
						arA1['h5] = 'h1c2;
						arA23['h5] = 'h380;
					end
					6: begin
						arIll['h5] = 1'b0;
						arA1['h5] = 'h1e3;
						arA23['h5] = 'h380;
					end
					7: begin
						arIll['h5] = 1'b0;
						arA1['h5] = 'ha;
						arA23['h5] = 'h380;
					end
					8: begin
						arIll['h5] = 1'b0;
						arA1['h5] = 'h1e2;
						arA23['h5] = 'h380;
					end
					default: begin
						arIll['h5] = 1'b1;
						arA1['h5] = 1'sbx;
						arA23['h5] = 1'sbx;
					end
				endcase
			3'b100:
				(* full_case, parallel_case *)
				case (col)
					0: begin
						arIll['h5] = 1'b0;
						arA1['h5] = 'h2d8;
						arA23['h5] = 1'sbx;
					end
					1: begin
						arIll['h5] = 1'b1;
						arA1['h5] = 1'sbx;
						arA23['h5] = 1'sbx;
					end
					2: begin
						arIll['h5] = 1'b0;
						arA1['h5] = 'h6;
						arA23['h5] = 'h2f3;
					end
					3: begin
						arIll['h5] = 1'b0;
						arA1['h5] = 'h21c;
						arA23['h5] = 'h2f3;
					end
					4: begin
						arIll['h5] = 1'b0;
						arA1['h5] = 'h103;
						arA23['h5] = 'h2f3;
					end
					5: begin
						arIll['h5] = 1'b0;
						arA1['h5] = 'h1c2;
						arA23['h5] = 'h2f3;
					end
					6: begin
						arIll['h5] = 1'b0;
						arA1['h5] = 'h1e3;
						arA23['h5] = 'h2f3;
					end
					7: begin
						arIll['h5] = 1'b0;
						arA1['h5] = 'ha;
						arA23['h5] = 'h2f3;
					end
					8: begin
						arIll['h5] = 1'b0;
						arA1['h5] = 'h1e2;
						arA23['h5] = 'h2f3;
					end
					default: begin
						arIll['h5] = 1'b1;
						arA1['h5] = 1'sbx;
						arA23['h5] = 1'sbx;
					end
				endcase
			3'b101:
				(* full_case, parallel_case *)
				case (col)
					0: begin
						arIll['h5] = 1'b0;
						arA1['h5] = 'h2d8;
						arA23['h5] = 1'sbx;
					end
					1: begin
						arIll['h5] = 1'b0;
						arA1['h5] = 'h2dc;
						arA23['h5] = 1'sbx;
					end
					2: begin
						arIll['h5] = 1'b0;
						arA1['h5] = 'h6;
						arA23['h5] = 'h2f3;
					end
					3: begin
						arIll['h5] = 1'b0;
						arA1['h5] = 'h21c;
						arA23['h5] = 'h2f3;
					end
					4: begin
						arIll['h5] = 1'b0;
						arA1['h5] = 'h103;
						arA23['h5] = 'h2f3;
					end
					5: begin
						arIll['h5] = 1'b0;
						arA1['h5] = 'h1c2;
						arA23['h5] = 'h2f3;
					end
					6: begin
						arIll['h5] = 1'b0;
						arA1['h5] = 'h1e3;
						arA23['h5] = 'h2f3;
					end
					7: begin
						arIll['h5] = 1'b0;
						arA1['h5] = 'ha;
						arA23['h5] = 'h2f3;
					end
					8: begin
						arIll['h5] = 1'b0;
						arA1['h5] = 'h1e2;
						arA23['h5] = 'h2f3;
					end
					default: begin
						arIll['h5] = 1'b1;
						arA1['h5] = 1'sbx;
						arA23['h5] = 1'sbx;
					end
				endcase
			3'b110:
				(* full_case, parallel_case *)
				case (col)
					0: begin
						arIll['h5] = 1'b0;
						arA1['h5] = 'h2dc;
						arA23['h5] = 1'sbx;
					end
					1: begin
						arIll['h5] = 1'b0;
						arA1['h5] = 'h2dc;
						arA23['h5] = 1'sbx;
					end
					2: begin
						arIll['h5] = 1'b0;
						arA1['h5] = 'hb;
						arA23['h5] = 'h2f7;
					end
					3: begin
						arIll['h5] = 1'b0;
						arA1['h5] = 'hf;
						arA23['h5] = 'h2f7;
					end
					4: begin
						arIll['h5] = 1'b0;
						arA1['h5] = 'h179;
						arA23['h5] = 'h2f7;
					end
					5: begin
						arIll['h5] = 1'b0;
						arA1['h5] = 'h1c6;
						arA23['h5] = 'h2f7;
					end
					6: begin
						arIll['h5] = 1'b0;
						arA1['h5] = 'h1e7;
						arA23['h5] = 'h2f7;
					end
					7: begin
						arIll['h5] = 1'b0;
						arA1['h5] = 'he;
						arA23['h5] = 'h2f7;
					end
					8: begin
						arIll['h5] = 1'b0;
						arA1['h5] = 'h1e6;
						arA23['h5] = 'h2f7;
					end
					default: begin
						arIll['h5] = 1'b1;
						arA1['h5] = 1'sbx;
						arA23['h5] = 1'sbx;
					end
				endcase
			3'b111:
				(* full_case, parallel_case *)
				case (col)
					0: begin
						arIll['h5] = 1'b0;
						arA1['h5] = 'h384;
						arA23['h5] = 1'sbx;
					end
					1: begin
						arIll['h5] = 1'b0;
						arA1['h5] = 'h6c;
						arA23['h5] = 1'sbx;
					end
					2: begin
						arIll['h5] = 1'b0;
						arA1['h5] = 'h6;
						arA23['h5] = 'h380;
					end
					3: begin
						arIll['h5] = 1'b0;
						arA1['h5] = 'h21c;
						arA23['h5] = 'h380;
					end
					4: begin
						arIll['h5] = 1'b0;
						arA1['h5] = 'h103;
						arA23['h5] = 'h380;
					end
					5: begin
						arIll['h5] = 1'b0;
						arA1['h5] = 'h1c2;
						arA23['h5] = 'h380;
					end
					6: begin
						arIll['h5] = 1'b0;
						arA1['h5] = 'h1e3;
						arA23['h5] = 'h380;
					end
					7: begin
						arIll['h5] = 1'b0;
						arA1['h5] = 'ha;
						arA23['h5] = 'h380;
					end
					8: begin
						arIll['h5] = 1'b0;
						arA1['h5] = 'h1e2;
						arA23['h5] = 'h380;
					end
					default: begin
						arIll['h5] = 1'b1;
						arA1['h5] = 1'sbx;
						arA23['h5] = 1'sbx;
					end
				endcase
		endcase
		(* full_case, parallel_case *)
		case (row86)
			3'b000:
				(* full_case, parallel_case *)
				case (col)
					0: begin
						arIll['h8] = 1'b0;
						arA1['h8] = 'h1c1;
						arA23['h8] = 1'sbx;
					end
					1: begin
						arIll['h8] = 1'b1;
						arA1['h8] = 1'sbx;
						arA23['h8] = 1'sbx;
					end
					2: begin
						arIll['h8] = 1'b0;
						arA1['h8] = 'h6;
						arA23['h8] = 'h1c3;
					end
					3: begin
						arIll['h8] = 1'b0;
						arA1['h8] = 'h21c;
						arA23['h8] = 'h1c3;
					end
					4: begin
						arIll['h8] = 1'b0;
						arA1['h8] = 'h103;
						arA23['h8] = 'h1c3;
					end
					5: begin
						arIll['h8] = 1'b0;
						arA1['h8] = 'h1c2;
						arA23['h8] = 'h1c3;
					end
					6: begin
						arIll['h8] = 1'b0;
						arA1['h8] = 'h1e3;
						arA23['h8] = 'h1c3;
					end
					7: begin
						arIll['h8] = 1'b0;
						arA1['h8] = 'ha;
						arA23['h8] = 'h1c3;
					end
					8: begin
						arIll['h8] = 1'b0;
						arA1['h8] = 'h1e2;
						arA23['h8] = 'h1c3;
					end
					9: begin
						arIll['h8] = 1'b0;
						arA1['h8] = 'h1c2;
						arA23['h8] = 'h1c3;
					end
					10: begin
						arIll['h8] = 1'b0;
						arA1['h8] = 'h1e3;
						arA23['h8] = 'h1c3;
					end
					11: begin
						arIll['h8] = 1'b0;
						arA1['h8] = 'hea;
						arA23['h8] = 'h1c1;
					end
					default: begin
						arIll['h8] = 1'b1;
						arA1['h8] = 1'sbx;
						arA23['h8] = 1'sbx;
					end
				endcase
			3'b001:
				(* full_case, parallel_case *)
				case (col)
					0: begin
						arIll['h8] = 1'b0;
						arA1['h8] = 'h1c1;
						arA23['h8] = 1'sbx;
					end
					1: begin
						arIll['h8] = 1'b1;
						arA1['h8] = 1'sbx;
						arA23['h8] = 1'sbx;
					end
					2: begin
						arIll['h8] = 1'b0;
						arA1['h8] = 'h6;
						arA23['h8] = 'h1c3;
					end
					3: begin
						arIll['h8] = 1'b0;
						arA1['h8] = 'h21c;
						arA23['h8] = 'h1c3;
					end
					4: begin
						arIll['h8] = 1'b0;
						arA1['h8] = 'h103;
						arA23['h8] = 'h1c3;
					end
					5: begin
						arIll['h8] = 1'b0;
						arA1['h8] = 'h1c2;
						arA23['h8] = 'h1c3;
					end
					6: begin
						arIll['h8] = 1'b0;
						arA1['h8] = 'h1e3;
						arA23['h8] = 'h1c3;
					end
					7: begin
						arIll['h8] = 1'b0;
						arA1['h8] = 'ha;
						arA23['h8] = 'h1c3;
					end
					8: begin
						arIll['h8] = 1'b0;
						arA1['h8] = 'h1e2;
						arA23['h8] = 'h1c3;
					end
					9: begin
						arIll['h8] = 1'b0;
						arA1['h8] = 'h1c2;
						arA23['h8] = 'h1c3;
					end
					10: begin
						arIll['h8] = 1'b0;
						arA1['h8] = 'h1e3;
						arA23['h8] = 'h1c3;
					end
					11: begin
						arIll['h8] = 1'b0;
						arA1['h8] = 'hea;
						arA23['h8] = 'h1c1;
					end
					default: begin
						arIll['h8] = 1'b1;
						arA1['h8] = 1'sbx;
						arA23['h8] = 1'sbx;
					end
				endcase
			3'b010:
				(* full_case, parallel_case *)
				case (col)
					0: begin
						arIll['h8] = 1'b0;
						arA1['h8] = 'h1c5;
						arA23['h8] = 1'sbx;
					end
					1: begin
						arIll['h8] = 1'b1;
						arA1['h8] = 1'sbx;
						arA23['h8] = 1'sbx;
					end
					2: begin
						arIll['h8] = 1'b0;
						arA1['h8] = 'hb;
						arA23['h8] = 'h1cb;
					end
					3: begin
						arIll['h8] = 1'b0;
						arA1['h8] = 'hf;
						arA23['h8] = 'h1cb;
					end
					4: begin
						arIll['h8] = 1'b0;
						arA1['h8] = 'h179;
						arA23['h8] = 'h1cb;
					end
					5: begin
						arIll['h8] = 1'b0;
						arA1['h8] = 'h1c6;
						arA23['h8] = 'h1cb;
					end
					6: begin
						arIll['h8] = 1'b0;
						arA1['h8] = 'h1e7;
						arA23['h8] = 'h1cb;
					end
					7: begin
						arIll['h8] = 1'b0;
						arA1['h8] = 'he;
						arA23['h8] = 'h1cb;
					end
					8: begin
						arIll['h8] = 1'b0;
						arA1['h8] = 'h1e6;
						arA23['h8] = 'h1cb;
					end
					9: begin
						arIll['h8] = 1'b0;
						arA1['h8] = 'h1c6;
						arA23['h8] = 'h1cb;
					end
					10: begin
						arIll['h8] = 1'b0;
						arA1['h8] = 'h1e7;
						arA23['h8] = 'h1cb;
					end
					11: begin
						arIll['h8] = 1'b0;
						arA1['h8] = 'ha7;
						arA23['h8] = 'h1c5;
					end
					default: begin
						arIll['h8] = 1'b1;
						arA1['h8] = 1'sbx;
						arA23['h8] = 1'sbx;
					end
				endcase
			3'b011:
				(* full_case, parallel_case *)
				case (col)
					0: begin
						arIll['h8] = 1'b0;
						arA1['h8] = 'ha6;
						arA23['h8] = 1'sbx;
					end
					1: begin
						arIll['h8] = 1'b1;
						arA1['h8] = 1'sbx;
						arA23['h8] = 1'sbx;
					end
					2: begin
						arIll['h8] = 1'b0;
						arA1['h8] = 'h6;
						arA23['h8] = 'ha4;
					end
					3: begin
						arIll['h8] = 1'b0;
						arA1['h8] = 'h21c;
						arA23['h8] = 'ha4;
					end
					4: begin
						arIll['h8] = 1'b0;
						arA1['h8] = 'h103;
						arA23['h8] = 'ha4;
					end
					5: begin
						arIll['h8] = 1'b0;
						arA1['h8] = 'h1c2;
						arA23['h8] = 'ha4;
					end
					6: begin
						arIll['h8] = 1'b0;
						arA1['h8] = 'h1e3;
						arA23['h8] = 'ha4;
					end
					7: begin
						arIll['h8] = 1'b0;
						arA1['h8] = 'ha;
						arA23['h8] = 'ha4;
					end
					8: begin
						arIll['h8] = 1'b0;
						arA1['h8] = 'h1e2;
						arA23['h8] = 'ha4;
					end
					9: begin
						arIll['h8] = 1'b0;
						arA1['h8] = 'h1c2;
						arA23['h8] = 'ha4;
					end
					10: begin
						arIll['h8] = 1'b0;
						arA1['h8] = 'h1e3;
						arA23['h8] = 'ha4;
					end
					11: begin
						arIll['h8] = 1'b0;
						arA1['h8] = 'hea;
						arA23['h8] = 'ha6;
					end
					default: begin
						arIll['h8] = 1'b1;
						arA1['h8] = 1'sbx;
						arA23['h8] = 1'sbx;
					end
				endcase
			3'b100:
				(* full_case, parallel_case *)
				case (col)
					0: begin
						arIll['h8] = 1'b0;
						arA1['h8] = 'h1cd;
						arA23['h8] = 1'sbx;
					end
					1: begin
						arIll['h8] = 1'b0;
						arA1['h8] = 'h107;
						arA23['h8] = 1'sbx;
					end
					2: begin
						arIll['h8] = 1'b0;
						arA1['h8] = 'h6;
						arA23['h8] = 'h299;
					end
					3: begin
						arIll['h8] = 1'b0;
						arA1['h8] = 'h21c;
						arA23['h8] = 'h299;
					end
					4: begin
						arIll['h8] = 1'b0;
						arA1['h8] = 'h103;
						arA23['h8] = 'h299;
					end
					5: begin
						arIll['h8] = 1'b0;
						arA1['h8] = 'h1c2;
						arA23['h8] = 'h299;
					end
					6: begin
						arIll['h8] = 1'b0;
						arA1['h8] = 'h1e3;
						arA23['h8] = 'h299;
					end
					7: begin
						arIll['h8] = 1'b0;
						arA1['h8] = 'ha;
						arA23['h8] = 'h299;
					end
					8: begin
						arIll['h8] = 1'b0;
						arA1['h8] = 'h1e2;
						arA23['h8] = 'h299;
					end
					9: begin
						arIll['h8] = 1'b1;
						arA1['h8] = 1'sbx;
						arA23['h8] = 1'sbx;
					end
					10: begin
						arIll['h8] = 1'b1;
						arA1['h8] = 1'sbx;
						arA23['h8] = 1'sbx;
					end
					11: begin
						arIll['h8] = 1'b1;
						arA1['h8] = 1'sbx;
						arA23['h8] = 1'sbx;
					end
					default: begin
						arIll['h8] = 1'b1;
						arA1['h8] = 1'sbx;
						arA23['h8] = 1'sbx;
					end
				endcase
			3'b101:
				(* full_case, parallel_case *)
				case (col)
					0: begin
						arIll['h8] = 1'b1;
						arA1['h8] = 1'sbx;
						arA23['h8] = 1'sbx;
					end
					1: begin
						arIll['h8] = 1'b1;
						arA1['h8] = 1'sbx;
						arA23['h8] = 1'sbx;
					end
					2: begin
						arIll['h8] = 1'b0;
						arA1['h8] = 'h6;
						arA23['h8] = 'h299;
					end
					3: begin
						arIll['h8] = 1'b0;
						arA1['h8] = 'h21c;
						arA23['h8] = 'h299;
					end
					4: begin
						arIll['h8] = 1'b0;
						arA1['h8] = 'h103;
						arA23['h8] = 'h299;
					end
					5: begin
						arIll['h8] = 1'b0;
						arA1['h8] = 'h1c2;
						arA23['h8] = 'h299;
					end
					6: begin
						arIll['h8] = 1'b0;
						arA1['h8] = 'h1e3;
						arA23['h8] = 'h299;
					end
					7: begin
						arIll['h8] = 1'b0;
						arA1['h8] = 'ha;
						arA23['h8] = 'h299;
					end
					8: begin
						arIll['h8] = 1'b0;
						arA1['h8] = 'h1e2;
						arA23['h8] = 'h299;
					end
					9: begin
						arIll['h8] = 1'b1;
						arA1['h8] = 1'sbx;
						arA23['h8] = 1'sbx;
					end
					10: begin
						arIll['h8] = 1'b1;
						arA1['h8] = 1'sbx;
						arA23['h8] = 1'sbx;
					end
					11: begin
						arIll['h8] = 1'b1;
						arA1['h8] = 1'sbx;
						arA23['h8] = 1'sbx;
					end
					default: begin
						arIll['h8] = 1'b1;
						arA1['h8] = 1'sbx;
						arA23['h8] = 1'sbx;
					end
				endcase
			3'b110:
				(* full_case, parallel_case *)
				case (col)
					0: begin
						arIll['h8] = 1'b1;
						arA1['h8] = 1'sbx;
						arA23['h8] = 1'sbx;
					end
					1: begin
						arIll['h8] = 1'b1;
						arA1['h8] = 1'sbx;
						arA23['h8] = 1'sbx;
					end
					2: begin
						arIll['h8] = 1'b0;
						arA1['h8] = 'hb;
						arA23['h8] = 'h29d;
					end
					3: begin
						arIll['h8] = 1'b0;
						arA1['h8] = 'hf;
						arA23['h8] = 'h29d;
					end
					4: begin
						arIll['h8] = 1'b0;
						arA1['h8] = 'h179;
						arA23['h8] = 'h29d;
					end
					5: begin
						arIll['h8] = 1'b0;
						arA1['h8] = 'h1c6;
						arA23['h8] = 'h29d;
					end
					6: begin
						arIll['h8] = 1'b0;
						arA1['h8] = 'h1e7;
						arA23['h8] = 'h29d;
					end
					7: begin
						arIll['h8] = 1'b0;
						arA1['h8] = 'he;
						arA23['h8] = 'h29d;
					end
					8: begin
						arIll['h8] = 1'b0;
						arA1['h8] = 'h1e6;
						arA23['h8] = 'h29d;
					end
					9: begin
						arIll['h8] = 1'b1;
						arA1['h8] = 1'sbx;
						arA23['h8] = 1'sbx;
					end
					10: begin
						arIll['h8] = 1'b1;
						arA1['h8] = 1'sbx;
						arA23['h8] = 1'sbx;
					end
					11: begin
						arIll['h8] = 1'b1;
						arA1['h8] = 1'sbx;
						arA23['h8] = 1'sbx;
					end
					default: begin
						arIll['h8] = 1'b1;
						arA1['h8] = 1'sbx;
						arA23['h8] = 1'sbx;
					end
				endcase
			3'b111:
				(* full_case, parallel_case *)
				case (col)
					0: begin
						arIll['h8] = 1'b0;
						arA1['h8] = 'hae;
						arA23['h8] = 1'sbx;
					end
					1: begin
						arIll['h8] = 1'b1;
						arA1['h8] = 1'sbx;
						arA23['h8] = 1'sbx;
					end
					2: begin
						arIll['h8] = 1'b0;
						arA1['h8] = 'h6;
						arA23['h8] = 'hac;
					end
					3: begin
						arIll['h8] = 1'b0;
						arA1['h8] = 'h21c;
						arA23['h8] = 'hac;
					end
					4: begin
						arIll['h8] = 1'b0;
						arA1['h8] = 'h103;
						arA23['h8] = 'hac;
					end
					5: begin
						arIll['h8] = 1'b0;
						arA1['h8] = 'h1c2;
						arA23['h8] = 'hac;
					end
					6: begin
						arIll['h8] = 1'b0;
						arA1['h8] = 'h1e3;
						arA23['h8] = 'hac;
					end
					7: begin
						arIll['h8] = 1'b0;
						arA1['h8] = 'ha;
						arA23['h8] = 'hac;
					end
					8: begin
						arIll['h8] = 1'b0;
						arA1['h8] = 'h1e2;
						arA23['h8] = 'hac;
					end
					9: begin
						arIll['h8] = 1'b0;
						arA1['h8] = 'h1c2;
						arA23['h8] = 'hac;
					end
					10: begin
						arIll['h8] = 1'b0;
						arA1['h8] = 'h1e3;
						arA23['h8] = 'hac;
					end
					11: begin
						arIll['h8] = 1'b0;
						arA1['h8] = 'hea;
						arA23['h8] = 'hae;
					end
					default: begin
						arIll['h8] = 1'b1;
						arA1['h8] = 1'sbx;
						arA23['h8] = 1'sbx;
					end
				endcase
		endcase
		(* full_case, parallel_case *)
		case (row86)
			3'b000:
				(* full_case, parallel_case *)
				case (col)
					0: begin
						arIll['h9] = 1'b0;
						arA1['h9] = 'h1c1;
						arA23['h9] = 1'sbx;
					end
					1: begin
						arIll['h9] = 1'b1;
						arA1['h9] = 1'sbx;
						arA23['h9] = 1'sbx;
					end
					2: begin
						arIll['h9] = 1'b0;
						arA1['h9] = 'h6;
						arA23['h9] = 'h1c3;
					end
					3: begin
						arIll['h9] = 1'b0;
						arA1['h9] = 'h21c;
						arA23['h9] = 'h1c3;
					end
					4: begin
						arIll['h9] = 1'b0;
						arA1['h9] = 'h103;
						arA23['h9] = 'h1c3;
					end
					5: begin
						arIll['h9] = 1'b0;
						arA1['h9] = 'h1c2;
						arA23['h9] = 'h1c3;
					end
					6: begin
						arIll['h9] = 1'b0;
						arA1['h9] = 'h1e3;
						arA23['h9] = 'h1c3;
					end
					7: begin
						arIll['h9] = 1'b0;
						arA1['h9] = 'ha;
						arA23['h9] = 'h1c3;
					end
					8: begin
						arIll['h9] = 1'b0;
						arA1['h9] = 'h1e2;
						arA23['h9] = 'h1c3;
					end
					9: begin
						arIll['h9] = 1'b0;
						arA1['h9] = 'h1c2;
						arA23['h9] = 'h1c3;
					end
					10: begin
						arIll['h9] = 1'b0;
						arA1['h9] = 'h1e3;
						arA23['h9] = 'h1c3;
					end
					11: begin
						arIll['h9] = 1'b0;
						arA1['h9] = 'hea;
						arA23['h9] = 'h1c1;
					end
					default: begin
						arIll['h9] = 1'b1;
						arA1['h9] = 1'sbx;
						arA23['h9] = 1'sbx;
					end
				endcase
			3'b001:
				(* full_case, parallel_case *)
				case (col)
					0: begin
						arIll['h9] = 1'b0;
						arA1['h9] = 'h1c1;
						arA23['h9] = 1'sbx;
					end
					1: begin
						arIll['h9] = 1'b0;
						arA1['h9] = 'h1c1;
						arA23['h9] = 1'sbx;
					end
					2: begin
						arIll['h9] = 1'b0;
						arA1['h9] = 'h6;
						arA23['h9] = 'h1c3;
					end
					3: begin
						arIll['h9] = 1'b0;
						arA1['h9] = 'h21c;
						arA23['h9] = 'h1c3;
					end
					4: begin
						arIll['h9] = 1'b0;
						arA1['h9] = 'h103;
						arA23['h9] = 'h1c3;
					end
					5: begin
						arIll['h9] = 1'b0;
						arA1['h9] = 'h1c2;
						arA23['h9] = 'h1c3;
					end
					6: begin
						arIll['h9] = 1'b0;
						arA1['h9] = 'h1e3;
						arA23['h9] = 'h1c3;
					end
					7: begin
						arIll['h9] = 1'b0;
						arA1['h9] = 'ha;
						arA23['h9] = 'h1c3;
					end
					8: begin
						arIll['h9] = 1'b0;
						arA1['h9] = 'h1e2;
						arA23['h9] = 'h1c3;
					end
					9: begin
						arIll['h9] = 1'b0;
						arA1['h9] = 'h1c2;
						arA23['h9] = 'h1c3;
					end
					10: begin
						arIll['h9] = 1'b0;
						arA1['h9] = 'h1e3;
						arA23['h9] = 'h1c3;
					end
					11: begin
						arIll['h9] = 1'b0;
						arA1['h9] = 'hea;
						arA23['h9] = 'h1c1;
					end
					default: begin
						arIll['h9] = 1'b1;
						arA1['h9] = 1'sbx;
						arA23['h9] = 1'sbx;
					end
				endcase
			3'b010:
				(* full_case, parallel_case *)
				case (col)
					0: begin
						arIll['h9] = 1'b0;
						arA1['h9] = 'h1c5;
						arA23['h9] = 1'sbx;
					end
					1: begin
						arIll['h9] = 1'b0;
						arA1['h9] = 'h1c5;
						arA23['h9] = 1'sbx;
					end
					2: begin
						arIll['h9] = 1'b0;
						arA1['h9] = 'hb;
						arA23['h9] = 'h1cb;
					end
					3: begin
						arIll['h9] = 1'b0;
						arA1['h9] = 'hf;
						arA23['h9] = 'h1cb;
					end
					4: begin
						arIll['h9] = 1'b0;
						arA1['h9] = 'h179;
						arA23['h9] = 'h1cb;
					end
					5: begin
						arIll['h9] = 1'b0;
						arA1['h9] = 'h1c6;
						arA23['h9] = 'h1cb;
					end
					6: begin
						arIll['h9] = 1'b0;
						arA1['h9] = 'h1e7;
						arA23['h9] = 'h1cb;
					end
					7: begin
						arIll['h9] = 1'b0;
						arA1['h9] = 'he;
						arA23['h9] = 'h1cb;
					end
					8: begin
						arIll['h9] = 1'b0;
						arA1['h9] = 'h1e6;
						arA23['h9] = 'h1cb;
					end
					9: begin
						arIll['h9] = 1'b0;
						arA1['h9] = 'h1c6;
						arA23['h9] = 'h1cb;
					end
					10: begin
						arIll['h9] = 1'b0;
						arA1['h9] = 'h1e7;
						arA23['h9] = 'h1cb;
					end
					11: begin
						arIll['h9] = 1'b0;
						arA1['h9] = 'ha7;
						arA23['h9] = 'h1c5;
					end
					default: begin
						arIll['h9] = 1'b1;
						arA1['h9] = 1'sbx;
						arA23['h9] = 1'sbx;
					end
				endcase
			3'b011:
				(* full_case, parallel_case *)
				case (col)
					0: begin
						arIll['h9] = 1'b0;
						arA1['h9] = 'h1c9;
						arA23['h9] = 1'sbx;
					end
					1: begin
						arIll['h9] = 1'b0;
						arA1['h9] = 'h1c9;
						arA23['h9] = 1'sbx;
					end
					2: begin
						arIll['h9] = 1'b0;
						arA1['h9] = 'h6;
						arA23['h9] = 'h1c7;
					end
					3: begin
						arIll['h9] = 1'b0;
						arA1['h9] = 'h21c;
						arA23['h9] = 'h1c7;
					end
					4: begin
						arIll['h9] = 1'b0;
						arA1['h9] = 'h103;
						arA23['h9] = 'h1c7;
					end
					5: begin
						arIll['h9] = 1'b0;
						arA1['h9] = 'h1c2;
						arA23['h9] = 'h1c7;
					end
					6: begin
						arIll['h9] = 1'b0;
						arA1['h9] = 'h1e3;
						arA23['h9] = 'h1c7;
					end
					7: begin
						arIll['h9] = 1'b0;
						arA1['h9] = 'ha;
						arA23['h9] = 'h1c7;
					end
					8: begin
						arIll['h9] = 1'b0;
						arA1['h9] = 'h1e2;
						arA23['h9] = 'h1c7;
					end
					9: begin
						arIll['h9] = 1'b0;
						arA1['h9] = 'h1c2;
						arA23['h9] = 'h1c7;
					end
					10: begin
						arIll['h9] = 1'b0;
						arA1['h9] = 'h1e3;
						arA23['h9] = 'h1c7;
					end
					11: begin
						arIll['h9] = 1'b0;
						arA1['h9] = 'hea;
						arA23['h9] = 'h1c9;
					end
					default: begin
						arIll['h9] = 1'b1;
						arA1['h9] = 1'sbx;
						arA23['h9] = 1'sbx;
					end
				endcase
			3'b100:
				(* full_case, parallel_case *)
				case (col)
					0: begin
						arIll['h9] = 1'b0;
						arA1['h9] = 'h1c1;
						arA23['h9] = 1'sbx;
					end
					1: begin
						arIll['h9] = 1'b0;
						arA1['h9] = 'h10f;
						arA23['h9] = 1'sbx;
					end
					2: begin
						arIll['h9] = 1'b0;
						arA1['h9] = 'h6;
						arA23['h9] = 'h299;
					end
					3: begin
						arIll['h9] = 1'b0;
						arA1['h9] = 'h21c;
						arA23['h9] = 'h299;
					end
					4: begin
						arIll['h9] = 1'b0;
						arA1['h9] = 'h103;
						arA23['h9] = 'h299;
					end
					5: begin
						arIll['h9] = 1'b0;
						arA1['h9] = 'h1c2;
						arA23['h9] = 'h299;
					end
					6: begin
						arIll['h9] = 1'b0;
						arA1['h9] = 'h1e3;
						arA23['h9] = 'h299;
					end
					7: begin
						arIll['h9] = 1'b0;
						arA1['h9] = 'ha;
						arA23['h9] = 'h299;
					end
					8: begin
						arIll['h9] = 1'b0;
						arA1['h9] = 'h1e2;
						arA23['h9] = 'h299;
					end
					9: begin
						arIll['h9] = 1'b1;
						arA1['h9] = 1'sbx;
						arA23['h9] = 1'sbx;
					end
					10: begin
						arIll['h9] = 1'b1;
						arA1['h9] = 1'sbx;
						arA23['h9] = 1'sbx;
					end
					11: begin
						arIll['h9] = 1'b1;
						arA1['h9] = 1'sbx;
						arA23['h9] = 1'sbx;
					end
					default: begin
						arIll['h9] = 1'b1;
						arA1['h9] = 1'sbx;
						arA23['h9] = 1'sbx;
					end
				endcase
			3'b101:
				(* full_case, parallel_case *)
				case (col)
					0: begin
						arIll['h9] = 1'b0;
						arA1['h9] = 'h1c1;
						arA23['h9] = 1'sbx;
					end
					1: begin
						arIll['h9] = 1'b0;
						arA1['h9] = 'h10f;
						arA23['h9] = 1'sbx;
					end
					2: begin
						arIll['h9] = 1'b0;
						arA1['h9] = 'h6;
						arA23['h9] = 'h299;
					end
					3: begin
						arIll['h9] = 1'b0;
						arA1['h9] = 'h21c;
						arA23['h9] = 'h299;
					end
					4: begin
						arIll['h9] = 1'b0;
						arA1['h9] = 'h103;
						arA23['h9] = 'h299;
					end
					5: begin
						arIll['h9] = 1'b0;
						arA1['h9] = 'h1c2;
						arA23['h9] = 'h299;
					end
					6: begin
						arIll['h9] = 1'b0;
						arA1['h9] = 'h1e3;
						arA23['h9] = 'h299;
					end
					7: begin
						arIll['h9] = 1'b0;
						arA1['h9] = 'ha;
						arA23['h9] = 'h299;
					end
					8: begin
						arIll['h9] = 1'b0;
						arA1['h9] = 'h1e2;
						arA23['h9] = 'h299;
					end
					9: begin
						arIll['h9] = 1'b1;
						arA1['h9] = 1'sbx;
						arA23['h9] = 1'sbx;
					end
					10: begin
						arIll['h9] = 1'b1;
						arA1['h9] = 1'sbx;
						arA23['h9] = 1'sbx;
					end
					11: begin
						arIll['h9] = 1'b1;
						arA1['h9] = 1'sbx;
						arA23['h9] = 1'sbx;
					end
					default: begin
						arIll['h9] = 1'b1;
						arA1['h9] = 1'sbx;
						arA23['h9] = 1'sbx;
					end
				endcase
			3'b110:
				(* full_case, parallel_case *)
				case (col)
					0: begin
						arIll['h9] = 1'b0;
						arA1['h9] = 'h1c5;
						arA23['h9] = 1'sbx;
					end
					1: begin
						arIll['h9] = 1'b0;
						arA1['h9] = 'h10b;
						arA23['h9] = 1'sbx;
					end
					2: begin
						arIll['h9] = 1'b0;
						arA1['h9] = 'hb;
						arA23['h9] = 'h29d;
					end
					3: begin
						arIll['h9] = 1'b0;
						arA1['h9] = 'hf;
						arA23['h9] = 'h29d;
					end
					4: begin
						arIll['h9] = 1'b0;
						arA1['h9] = 'h179;
						arA23['h9] = 'h29d;
					end
					5: begin
						arIll['h9] = 1'b0;
						arA1['h9] = 'h1c6;
						arA23['h9] = 'h29d;
					end
					6: begin
						arIll['h9] = 1'b0;
						arA1['h9] = 'h1e7;
						arA23['h9] = 'h29d;
					end
					7: begin
						arIll['h9] = 1'b0;
						arA1['h9] = 'he;
						arA23['h9] = 'h29d;
					end
					8: begin
						arIll['h9] = 1'b0;
						arA1['h9] = 'h1e6;
						arA23['h9] = 'h29d;
					end
					9: begin
						arIll['h9] = 1'b1;
						arA1['h9] = 1'sbx;
						arA23['h9] = 1'sbx;
					end
					10: begin
						arIll['h9] = 1'b1;
						arA1['h9] = 1'sbx;
						arA23['h9] = 1'sbx;
					end
					11: begin
						arIll['h9] = 1'b1;
						arA1['h9] = 1'sbx;
						arA23['h9] = 1'sbx;
					end
					default: begin
						arIll['h9] = 1'b1;
						arA1['h9] = 1'sbx;
						arA23['h9] = 1'sbx;
					end
				endcase
			3'b111:
				(* full_case, parallel_case *)
				case (col)
					0: begin
						arIll['h9] = 1'b0;
						arA1['h9] = 'h1c5;
						arA23['h9] = 1'sbx;
					end
					1: begin
						arIll['h9] = 1'b0;
						arA1['h9] = 'h1c5;
						arA23['h9] = 1'sbx;
					end
					2: begin
						arIll['h9] = 1'b0;
						arA1['h9] = 'hb;
						arA23['h9] = 'h1cb;
					end
					3: begin
						arIll['h9] = 1'b0;
						arA1['h9] = 'hf;
						arA23['h9] = 'h1cb;
					end
					4: begin
						arIll['h9] = 1'b0;
						arA1['h9] = 'h179;
						arA23['h9] = 'h1cb;
					end
					5: begin
						arIll['h9] = 1'b0;
						arA1['h9] = 'h1c6;
						arA23['h9] = 'h1cb;
					end
					6: begin
						arIll['h9] = 1'b0;
						arA1['h9] = 'h1e7;
						arA23['h9] = 'h1cb;
					end
					7: begin
						arIll['h9] = 1'b0;
						arA1['h9] = 'he;
						arA23['h9] = 'h1cb;
					end
					8: begin
						arIll['h9] = 1'b0;
						arA1['h9] = 'h1e6;
						arA23['h9] = 'h1cb;
					end
					9: begin
						arIll['h9] = 1'b0;
						arA1['h9] = 'h1c6;
						arA23['h9] = 'h1cb;
					end
					10: begin
						arIll['h9] = 1'b0;
						arA1['h9] = 'h1e7;
						arA23['h9] = 'h1cb;
					end
					11: begin
						arIll['h9] = 1'b0;
						arA1['h9] = 'ha7;
						arA23['h9] = 'h1c5;
					end
					default: begin
						arIll['h9] = 1'b1;
						arA1['h9] = 1'sbx;
						arA23['h9] = 1'sbx;
					end
				endcase
		endcase
		(* full_case, parallel_case *)
		case (row86)
			3'b000:
				(* full_case, parallel_case *)
				case (col)
					0: begin
						arIll['hb] = 1'b0;
						arA1['hb] = 'h1d1;
						arA23['hb] = 1'sbx;
					end
					1: begin
						arIll['hb] = 1'b1;
						arA1['hb] = 1'sbx;
						arA23['hb] = 1'sbx;
					end
					2: begin
						arIll['hb] = 1'b0;
						arA1['hb] = 'h6;
						arA23['hb] = 'h1d3;
					end
					3: begin
						arIll['hb] = 1'b0;
						arA1['hb] = 'h21c;
						arA23['hb] = 'h1d3;
					end
					4: begin
						arIll['hb] = 1'b0;
						arA1['hb] = 'h103;
						arA23['hb] = 'h1d3;
					end
					5: begin
						arIll['hb] = 1'b0;
						arA1['hb] = 'h1c2;
						arA23['hb] = 'h1d3;
					end
					6: begin
						arIll['hb] = 1'b0;
						arA1['hb] = 'h1e3;
						arA23['hb] = 'h1d3;
					end
					7: begin
						arIll['hb] = 1'b0;
						arA1['hb] = 'ha;
						arA23['hb] = 'h1d3;
					end
					8: begin
						arIll['hb] = 1'b0;
						arA1['hb] = 'h1e2;
						arA23['hb] = 'h1d3;
					end
					9: begin
						arIll['hb] = 1'b0;
						arA1['hb] = 'h1c2;
						arA23['hb] = 'h1d3;
					end
					10: begin
						arIll['hb] = 1'b0;
						arA1['hb] = 'h1e3;
						arA23['hb] = 'h1d3;
					end
					11: begin
						arIll['hb] = 1'b0;
						arA1['hb] = 'hea;
						arA23['hb] = 'h1d1;
					end
					default: begin
						arIll['hb] = 1'b1;
						arA1['hb] = 1'sbx;
						arA23['hb] = 1'sbx;
					end
				endcase
			3'b001:
				(* full_case, parallel_case *)
				case (col)
					0: begin
						arIll['hb] = 1'b0;
						arA1['hb] = 'h1d1;
						arA23['hb] = 1'sbx;
					end
					1: begin
						arIll['hb] = 1'b0;
						arA1['hb] = 'h1d1;
						arA23['hb] = 1'sbx;
					end
					2: begin
						arIll['hb] = 1'b0;
						arA1['hb] = 'h6;
						arA23['hb] = 'h1d3;
					end
					3: begin
						arIll['hb] = 1'b0;
						arA1['hb] = 'h21c;
						arA23['hb] = 'h1d3;
					end
					4: begin
						arIll['hb] = 1'b0;
						arA1['hb] = 'h103;
						arA23['hb] = 'h1d3;
					end
					5: begin
						arIll['hb] = 1'b0;
						arA1['hb] = 'h1c2;
						arA23['hb] = 'h1d3;
					end
					6: begin
						arIll['hb] = 1'b0;
						arA1['hb] = 'h1e3;
						arA23['hb] = 'h1d3;
					end
					7: begin
						arIll['hb] = 1'b0;
						arA1['hb] = 'ha;
						arA23['hb] = 'h1d3;
					end
					8: begin
						arIll['hb] = 1'b0;
						arA1['hb] = 'h1e2;
						arA23['hb] = 'h1d3;
					end
					9: begin
						arIll['hb] = 1'b0;
						arA1['hb] = 'h1c2;
						arA23['hb] = 'h1d3;
					end
					10: begin
						arIll['hb] = 1'b0;
						arA1['hb] = 'h1e3;
						arA23['hb] = 'h1d3;
					end
					11: begin
						arIll['hb] = 1'b0;
						arA1['hb] = 'hea;
						arA23['hb] = 'h1d1;
					end
					default: begin
						arIll['hb] = 1'b1;
						arA1['hb] = 1'sbx;
						arA23['hb] = 1'sbx;
					end
				endcase
			3'b010:
				(* full_case, parallel_case *)
				case (col)
					0: begin
						arIll['hb] = 1'b0;
						arA1['hb] = 'h1d5;
						arA23['hb] = 1'sbx;
					end
					1: begin
						arIll['hb] = 1'b0;
						arA1['hb] = 'h1d5;
						arA23['hb] = 1'sbx;
					end
					2: begin
						arIll['hb] = 1'b0;
						arA1['hb] = 'hb;
						arA23['hb] = 'h1d7;
					end
					3: begin
						arIll['hb] = 1'b0;
						arA1['hb] = 'hf;
						arA23['hb] = 'h1d7;
					end
					4: begin
						arIll['hb] = 1'b0;
						arA1['hb] = 'h179;
						arA23['hb] = 'h1d7;
					end
					5: begin
						arIll['hb] = 1'b0;
						arA1['hb] = 'h1c6;
						arA23['hb] = 'h1d7;
					end
					6: begin
						arIll['hb] = 1'b0;
						arA1['hb] = 'h1e7;
						arA23['hb] = 'h1d7;
					end
					7: begin
						arIll['hb] = 1'b0;
						arA1['hb] = 'he;
						arA23['hb] = 'h1d7;
					end
					8: begin
						arIll['hb] = 1'b0;
						arA1['hb] = 'h1e6;
						arA23['hb] = 'h1d7;
					end
					9: begin
						arIll['hb] = 1'b0;
						arA1['hb] = 'h1c6;
						arA23['hb] = 'h1d7;
					end
					10: begin
						arIll['hb] = 1'b0;
						arA1['hb] = 'h1e7;
						arA23['hb] = 'h1d7;
					end
					11: begin
						arIll['hb] = 1'b0;
						arA1['hb] = 'ha7;
						arA23['hb] = 'h1d5;
					end
					default: begin
						arIll['hb] = 1'b1;
						arA1['hb] = 1'sbx;
						arA23['hb] = 1'sbx;
					end
				endcase
			3'b011:
				(* full_case, parallel_case *)
				case (col)
					0: begin
						arIll['hb] = 1'b0;
						arA1['hb] = 'h1d9;
						arA23['hb] = 1'sbx;
					end
					1: begin
						arIll['hb] = 1'b0;
						arA1['hb] = 'h1d9;
						arA23['hb] = 1'sbx;
					end
					2: begin
						arIll['hb] = 1'b0;
						arA1['hb] = 'h6;
						arA23['hb] = 'h1cf;
					end
					3: begin
						arIll['hb] = 1'b0;
						arA1['hb] = 'h21c;
						arA23['hb] = 'h1cf;
					end
					4: begin
						arIll['hb] = 1'b0;
						arA1['hb] = 'h103;
						arA23['hb] = 'h1cf;
					end
					5: begin
						arIll['hb] = 1'b0;
						arA1['hb] = 'h1c2;
						arA23['hb] = 'h1cf;
					end
					6: begin
						arIll['hb] = 1'b0;
						arA1['hb] = 'h1e3;
						arA23['hb] = 'h1cf;
					end
					7: begin
						arIll['hb] = 1'b0;
						arA1['hb] = 'ha;
						arA23['hb] = 'h1cf;
					end
					8: begin
						arIll['hb] = 1'b0;
						arA1['hb] = 'h1e2;
						arA23['hb] = 'h1cf;
					end
					9: begin
						arIll['hb] = 1'b0;
						arA1['hb] = 'h1c2;
						arA23['hb] = 'h1cf;
					end
					10: begin
						arIll['hb] = 1'b0;
						arA1['hb] = 'h1e3;
						arA23['hb] = 'h1cf;
					end
					11: begin
						arIll['hb] = 1'b0;
						arA1['hb] = 'hea;
						arA23['hb] = 'h1d9;
					end
					default: begin
						arIll['hb] = 1'b1;
						arA1['hb] = 1'sbx;
						arA23['hb] = 1'sbx;
					end
				endcase
			3'b100:
				(* full_case, parallel_case *)
				case (col)
					0: begin
						arIll['hb] = 1'b0;
						arA1['hb] = 'h100;
						arA23['hb] = 1'sbx;
					end
					1: begin
						arIll['hb] = 1'b0;
						arA1['hb] = 'h6b;
						arA23['hb] = 1'sbx;
					end
					2: begin
						arIll['hb] = 1'b0;
						arA1['hb] = 'h6;
						arA23['hb] = 'h299;
					end
					3: begin
						arIll['hb] = 1'b0;
						arA1['hb] = 'h21c;
						arA23['hb] = 'h299;
					end
					4: begin
						arIll['hb] = 1'b0;
						arA1['hb] = 'h103;
						arA23['hb] = 'h299;
					end
					5: begin
						arIll['hb] = 1'b0;
						arA1['hb] = 'h1c2;
						arA23['hb] = 'h299;
					end
					6: begin
						arIll['hb] = 1'b0;
						arA1['hb] = 'h1e3;
						arA23['hb] = 'h299;
					end
					7: begin
						arIll['hb] = 1'b0;
						arA1['hb] = 'ha;
						arA23['hb] = 'h299;
					end
					8: begin
						arIll['hb] = 1'b0;
						arA1['hb] = 'h1e2;
						arA23['hb] = 'h299;
					end
					9: begin
						arIll['hb] = 1'b1;
						arA1['hb] = 1'sbx;
						arA23['hb] = 1'sbx;
					end
					10: begin
						arIll['hb] = 1'b1;
						arA1['hb] = 1'sbx;
						arA23['hb] = 1'sbx;
					end
					11: begin
						arIll['hb] = 1'b1;
						arA1['hb] = 1'sbx;
						arA23['hb] = 1'sbx;
					end
					default: begin
						arIll['hb] = 1'b1;
						arA1['hb] = 1'sbx;
						arA23['hb] = 1'sbx;
					end
				endcase
			3'b101:
				(* full_case, parallel_case *)
				case (col)
					0: begin
						arIll['hb] = 1'b0;
						arA1['hb] = 'h100;
						arA23['hb] = 1'sbx;
					end
					1: begin
						arIll['hb] = 1'b0;
						arA1['hb] = 'h6b;
						arA23['hb] = 1'sbx;
					end
					2: begin
						arIll['hb] = 1'b0;
						arA1['hb] = 'h6;
						arA23['hb] = 'h299;
					end
					3: begin
						arIll['hb] = 1'b0;
						arA1['hb] = 'h21c;
						arA23['hb] = 'h299;
					end
					4: begin
						arIll['hb] = 1'b0;
						arA1['hb] = 'h103;
						arA23['hb] = 'h299;
					end
					5: begin
						arIll['hb] = 1'b0;
						arA1['hb] = 'h1c2;
						arA23['hb] = 'h299;
					end
					6: begin
						arIll['hb] = 1'b0;
						arA1['hb] = 'h1e3;
						arA23['hb] = 'h299;
					end
					7: begin
						arIll['hb] = 1'b0;
						arA1['hb] = 'ha;
						arA23['hb] = 'h299;
					end
					8: begin
						arIll['hb] = 1'b0;
						arA1['hb] = 'h1e2;
						arA23['hb] = 'h299;
					end
					9: begin
						arIll['hb] = 1'b1;
						arA1['hb] = 1'sbx;
						arA23['hb] = 1'sbx;
					end
					10: begin
						arIll['hb] = 1'b1;
						arA1['hb] = 1'sbx;
						arA23['hb] = 1'sbx;
					end
					11: begin
						arIll['hb] = 1'b1;
						arA1['hb] = 1'sbx;
						arA23['hb] = 1'sbx;
					end
					default: begin
						arIll['hb] = 1'b1;
						arA1['hb] = 1'sbx;
						arA23['hb] = 1'sbx;
					end
				endcase
			3'b110:
				(* full_case, parallel_case *)
				case (col)
					0: begin
						arIll['hb] = 1'b0;
						arA1['hb] = 'h10c;
						arA23['hb] = 1'sbx;
					end
					1: begin
						arIll['hb] = 1'b0;
						arA1['hb] = 'h6f;
						arA23['hb] = 1'sbx;
					end
					2: begin
						arIll['hb] = 1'b0;
						arA1['hb] = 'hb;
						arA23['hb] = 'h29d;
					end
					3: begin
						arIll['hb] = 1'b0;
						arA1['hb] = 'hf;
						arA23['hb] = 'h29d;
					end
					4: begin
						arIll['hb] = 1'b0;
						arA1['hb] = 'h179;
						arA23['hb] = 'h29d;
					end
					5: begin
						arIll['hb] = 1'b0;
						arA1['hb] = 'h1c6;
						arA23['hb] = 'h29d;
					end
					6: begin
						arIll['hb] = 1'b0;
						arA1['hb] = 'h1e7;
						arA23['hb] = 'h29d;
					end
					7: begin
						arIll['hb] = 1'b0;
						arA1['hb] = 'he;
						arA23['hb] = 'h29d;
					end
					8: begin
						arIll['hb] = 1'b0;
						arA1['hb] = 'h1e6;
						arA23['hb] = 'h29d;
					end
					9: begin
						arIll['hb] = 1'b1;
						arA1['hb] = 1'sbx;
						arA23['hb] = 1'sbx;
					end
					10: begin
						arIll['hb] = 1'b1;
						arA1['hb] = 1'sbx;
						arA23['hb] = 1'sbx;
					end
					11: begin
						arIll['hb] = 1'b1;
						arA1['hb] = 1'sbx;
						arA23['hb] = 1'sbx;
					end
					default: begin
						arIll['hb] = 1'b1;
						arA1['hb] = 1'sbx;
						arA23['hb] = 1'sbx;
					end
				endcase
			3'b111:
				(* full_case, parallel_case *)
				case (col)
					0: begin
						arIll['hb] = 1'b0;
						arA1['hb] = 'h1d5;
						arA23['hb] = 1'sbx;
					end
					1: begin
						arIll['hb] = 1'b0;
						arA1['hb] = 'h1d5;
						arA23['hb] = 1'sbx;
					end
					2: begin
						arIll['hb] = 1'b0;
						arA1['hb] = 'hb;
						arA23['hb] = 'h1d7;
					end
					3: begin
						arIll['hb] = 1'b0;
						arA1['hb] = 'hf;
						arA23['hb] = 'h1d7;
					end
					4: begin
						arIll['hb] = 1'b0;
						arA1['hb] = 'h179;
						arA23['hb] = 'h1d7;
					end
					5: begin
						arIll['hb] = 1'b0;
						arA1['hb] = 'h1c6;
						arA23['hb] = 'h1d7;
					end
					6: begin
						arIll['hb] = 1'b0;
						arA1['hb] = 'h1e7;
						arA23['hb] = 'h1d7;
					end
					7: begin
						arIll['hb] = 1'b0;
						arA1['hb] = 'he;
						arA23['hb] = 'h1d7;
					end
					8: begin
						arIll['hb] = 1'b0;
						arA1['hb] = 'h1e6;
						arA23['hb] = 'h1d7;
					end
					9: begin
						arIll['hb] = 1'b0;
						arA1['hb] = 'h1c6;
						arA23['hb] = 'h1d7;
					end
					10: begin
						arIll['hb] = 1'b0;
						arA1['hb] = 'h1e7;
						arA23['hb] = 'h1d7;
					end
					11: begin
						arIll['hb] = 1'b0;
						arA1['hb] = 'ha7;
						arA23['hb] = 'h1d5;
					end
					default: begin
						arIll['hb] = 1'b1;
						arA1['hb] = 1'sbx;
						arA23['hb] = 1'sbx;
					end
				endcase
		endcase
		(* full_case, parallel_case *)
		case (row86)
			3'b000:
				(* full_case, parallel_case *)
				case (col)
					0: begin
						arIll['hc] = 1'b0;
						arA1['hc] = 'h1c1;
						arA23['hc] = 1'sbx;
					end
					1: begin
						arIll['hc] = 1'b1;
						arA1['hc] = 1'sbx;
						arA23['hc] = 1'sbx;
					end
					2: begin
						arIll['hc] = 1'b0;
						arA1['hc] = 'h6;
						arA23['hc] = 'h1c3;
					end
					3: begin
						arIll['hc] = 1'b0;
						arA1['hc] = 'h21c;
						arA23['hc] = 'h1c3;
					end
					4: begin
						arIll['hc] = 1'b0;
						arA1['hc] = 'h103;
						arA23['hc] = 'h1c3;
					end
					5: begin
						arIll['hc] = 1'b0;
						arA1['hc] = 'h1c2;
						arA23['hc] = 'h1c3;
					end
					6: begin
						arIll['hc] = 1'b0;
						arA1['hc] = 'h1e3;
						arA23['hc] = 'h1c3;
					end
					7: begin
						arIll['hc] = 1'b0;
						arA1['hc] = 'ha;
						arA23['hc] = 'h1c3;
					end
					8: begin
						arIll['hc] = 1'b0;
						arA1['hc] = 'h1e2;
						arA23['hc] = 'h1c3;
					end
					9: begin
						arIll['hc] = 1'b0;
						arA1['hc] = 'h1c2;
						arA23['hc] = 'h1c3;
					end
					10: begin
						arIll['hc] = 1'b0;
						arA1['hc] = 'h1e3;
						arA23['hc] = 'h1c3;
					end
					11: begin
						arIll['hc] = 1'b0;
						arA1['hc] = 'hea;
						arA23['hc] = 'h1c1;
					end
					default: begin
						arIll['hc] = 1'b1;
						arA1['hc] = 1'sbx;
						arA23['hc] = 1'sbx;
					end
				endcase
			3'b001:
				(* full_case, parallel_case *)
				case (col)
					0: begin
						arIll['hc] = 1'b0;
						arA1['hc] = 'h1c1;
						arA23['hc] = 1'sbx;
					end
					1: begin
						arIll['hc] = 1'b1;
						arA1['hc] = 1'sbx;
						arA23['hc] = 1'sbx;
					end
					2: begin
						arIll['hc] = 1'b0;
						arA1['hc] = 'h6;
						arA23['hc] = 'h1c3;
					end
					3: begin
						arIll['hc] = 1'b0;
						arA1['hc] = 'h21c;
						arA23['hc] = 'h1c3;
					end
					4: begin
						arIll['hc] = 1'b0;
						arA1['hc] = 'h103;
						arA23['hc] = 'h1c3;
					end
					5: begin
						arIll['hc] = 1'b0;
						arA1['hc] = 'h1c2;
						arA23['hc] = 'h1c3;
					end
					6: begin
						arIll['hc] = 1'b0;
						arA1['hc] = 'h1e3;
						arA23['hc] = 'h1c3;
					end
					7: begin
						arIll['hc] = 1'b0;
						arA1['hc] = 'ha;
						arA23['hc] = 'h1c3;
					end
					8: begin
						arIll['hc] = 1'b0;
						arA1['hc] = 'h1e2;
						arA23['hc] = 'h1c3;
					end
					9: begin
						arIll['hc] = 1'b0;
						arA1['hc] = 'h1c2;
						arA23['hc] = 'h1c3;
					end
					10: begin
						arIll['hc] = 1'b0;
						arA1['hc] = 'h1e3;
						arA23['hc] = 'h1c3;
					end
					11: begin
						arIll['hc] = 1'b0;
						arA1['hc] = 'hea;
						arA23['hc] = 'h1c1;
					end
					default: begin
						arIll['hc] = 1'b1;
						arA1['hc] = 1'sbx;
						arA23['hc] = 1'sbx;
					end
				endcase
			3'b010:
				(* full_case, parallel_case *)
				case (col)
					0: begin
						arIll['hc] = 1'b0;
						arA1['hc] = 'h1c5;
						arA23['hc] = 1'sbx;
					end
					1: begin
						arIll['hc] = 1'b1;
						arA1['hc] = 1'sbx;
						arA23['hc] = 1'sbx;
					end
					2: begin
						arIll['hc] = 1'b0;
						arA1['hc] = 'hb;
						arA23['hc] = 'h1cb;
					end
					3: begin
						arIll['hc] = 1'b0;
						arA1['hc] = 'hf;
						arA23['hc] = 'h1cb;
					end
					4: begin
						arIll['hc] = 1'b0;
						arA1['hc] = 'h179;
						arA23['hc] = 'h1cb;
					end
					5: begin
						arIll['hc] = 1'b0;
						arA1['hc] = 'h1c6;
						arA23['hc] = 'h1cb;
					end
					6: begin
						arIll['hc] = 1'b0;
						arA1['hc] = 'h1e7;
						arA23['hc] = 'h1cb;
					end
					7: begin
						arIll['hc] = 1'b0;
						arA1['hc] = 'he;
						arA23['hc] = 'h1cb;
					end
					8: begin
						arIll['hc] = 1'b0;
						arA1['hc] = 'h1e6;
						arA23['hc] = 'h1cb;
					end
					9: begin
						arIll['hc] = 1'b0;
						arA1['hc] = 'h1c6;
						arA23['hc] = 'h1cb;
					end
					10: begin
						arIll['hc] = 1'b0;
						arA1['hc] = 'h1e7;
						arA23['hc] = 'h1cb;
					end
					11: begin
						arIll['hc] = 1'b0;
						arA1['hc] = 'ha7;
						arA23['hc] = 'h1c5;
					end
					default: begin
						arIll['hc] = 1'b1;
						arA1['hc] = 1'sbx;
						arA23['hc] = 1'sbx;
					end
				endcase
			3'b011:
				(* full_case, parallel_case *)
				case (col)
					0: begin
						arIll['hc] = 1'b0;
						arA1['hc] = 'h15b;
						arA23['hc] = 1'sbx;
					end
					1: begin
						arIll['hc] = 1'b1;
						arA1['hc] = 1'sbx;
						arA23['hc] = 1'sbx;
					end
					2: begin
						arIll['hc] = 1'b0;
						arA1['hc] = 'h6;
						arA23['hc] = 'h15a;
					end
					3: begin
						arIll['hc] = 1'b0;
						arA1['hc] = 'h21c;
						arA23['hc] = 'h15a;
					end
					4: begin
						arIll['hc] = 1'b0;
						arA1['hc] = 'h103;
						arA23['hc] = 'h15a;
					end
					5: begin
						arIll['hc] = 1'b0;
						arA1['hc] = 'h1c2;
						arA23['hc] = 'h15a;
					end
					6: begin
						arIll['hc] = 1'b0;
						arA1['hc] = 'h1e3;
						arA23['hc] = 'h15a;
					end
					7: begin
						arIll['hc] = 1'b0;
						arA1['hc] = 'ha;
						arA23['hc] = 'h15a;
					end
					8: begin
						arIll['hc] = 1'b0;
						arA1['hc] = 'h1e2;
						arA23['hc] = 'h15a;
					end
					9: begin
						arIll['hc] = 1'b0;
						arA1['hc] = 'h1c2;
						arA23['hc] = 'h15a;
					end
					10: begin
						arIll['hc] = 1'b0;
						arA1['hc] = 'h1e3;
						arA23['hc] = 'h15a;
					end
					11: begin
						arIll['hc] = 1'b0;
						arA1['hc] = 'hea;
						arA23['hc] = 'h15b;
					end
					default: begin
						arIll['hc] = 1'b1;
						arA1['hc] = 1'sbx;
						arA23['hc] = 1'sbx;
					end
				endcase
			3'b100:
				(* full_case, parallel_case *)
				case (col)
					0: begin
						arIll['hc] = 1'b0;
						arA1['hc] = 'h1cd;
						arA23['hc] = 1'sbx;
					end
					1: begin
						arIll['hc] = 1'b0;
						arA1['hc] = 'h107;
						arA23['hc] = 1'sbx;
					end
					2: begin
						arIll['hc] = 1'b0;
						arA1['hc] = 'h6;
						arA23['hc] = 'h299;
					end
					3: begin
						arIll['hc] = 1'b0;
						arA1['hc] = 'h21c;
						arA23['hc] = 'h299;
					end
					4: begin
						arIll['hc] = 1'b0;
						arA1['hc] = 'h103;
						arA23['hc] = 'h299;
					end
					5: begin
						arIll['hc] = 1'b0;
						arA1['hc] = 'h1c2;
						arA23['hc] = 'h299;
					end
					6: begin
						arIll['hc] = 1'b0;
						arA1['hc] = 'h1e3;
						arA23['hc] = 'h299;
					end
					7: begin
						arIll['hc] = 1'b0;
						arA1['hc] = 'ha;
						arA23['hc] = 'h299;
					end
					8: begin
						arIll['hc] = 1'b0;
						arA1['hc] = 'h1e2;
						arA23['hc] = 'h299;
					end
					9: begin
						arIll['hc] = 1'b1;
						arA1['hc] = 1'sbx;
						arA23['hc] = 1'sbx;
					end
					10: begin
						arIll['hc] = 1'b1;
						arA1['hc] = 1'sbx;
						arA23['hc] = 1'sbx;
					end
					11: begin
						arIll['hc] = 1'b1;
						arA1['hc] = 1'sbx;
						arA23['hc] = 1'sbx;
					end
					default: begin
						arIll['hc] = 1'b1;
						arA1['hc] = 1'sbx;
						arA23['hc] = 1'sbx;
					end
				endcase
			3'b101:
				(* full_case, parallel_case *)
				case (col)
					0: begin
						arIll['hc] = 1'b0;
						arA1['hc] = 'h3e3;
						arA23['hc] = 1'sbx;
					end
					1: begin
						arIll['hc] = 1'b0;
						arA1['hc] = 'h3e3;
						arA23['hc] = 1'sbx;
					end
					2: begin
						arIll['hc] = 1'b0;
						arA1['hc] = 'h6;
						arA23['hc] = 'h299;
					end
					3: begin
						arIll['hc] = 1'b0;
						arA1['hc] = 'h21c;
						arA23['hc] = 'h299;
					end
					4: begin
						arIll['hc] = 1'b0;
						arA1['hc] = 'h103;
						arA23['hc] = 'h299;
					end
					5: begin
						arIll['hc] = 1'b0;
						arA1['hc] = 'h1c2;
						arA23['hc] = 'h299;
					end
					6: begin
						arIll['hc] = 1'b0;
						arA1['hc] = 'h1e3;
						arA23['hc] = 'h299;
					end
					7: begin
						arIll['hc] = 1'b0;
						arA1['hc] = 'ha;
						arA23['hc] = 'h299;
					end
					8: begin
						arIll['hc] = 1'b0;
						arA1['hc] = 'h1e2;
						arA23['hc] = 'h299;
					end
					9: begin
						arIll['hc] = 1'b1;
						arA1['hc] = 1'sbx;
						arA23['hc] = 1'sbx;
					end
					10: begin
						arIll['hc] = 1'b1;
						arA1['hc] = 1'sbx;
						arA23['hc] = 1'sbx;
					end
					11: begin
						arIll['hc] = 1'b1;
						arA1['hc] = 1'sbx;
						arA23['hc] = 1'sbx;
					end
					default: begin
						arIll['hc] = 1'b1;
						arA1['hc] = 1'sbx;
						arA23['hc] = 1'sbx;
					end
				endcase
			3'b110:
				(* full_case, parallel_case *)
				case (col)
					0: begin
						arIll['hc] = 1'b1;
						arA1['hc] = 1'sbx;
						arA23['hc] = 1'sbx;
					end
					1: begin
						arIll['hc] = 1'b0;
						arA1['hc] = 'h3e3;
						arA23['hc] = 1'sbx;
					end
					2: begin
						arIll['hc] = 1'b0;
						arA1['hc] = 'hb;
						arA23['hc] = 'h29d;
					end
					3: begin
						arIll['hc] = 1'b0;
						arA1['hc] = 'hf;
						arA23['hc] = 'h29d;
					end
					4: begin
						arIll['hc] = 1'b0;
						arA1['hc] = 'h179;
						arA23['hc] = 'h29d;
					end
					5: begin
						arIll['hc] = 1'b0;
						arA1['hc] = 'h1c6;
						arA23['hc] = 'h29d;
					end
					6: begin
						arIll['hc] = 1'b0;
						arA1['hc] = 'h1e7;
						arA23['hc] = 'h29d;
					end
					7: begin
						arIll['hc] = 1'b0;
						arA1['hc] = 'he;
						arA23['hc] = 'h29d;
					end
					8: begin
						arIll['hc] = 1'b0;
						arA1['hc] = 'h1e6;
						arA23['hc] = 'h29d;
					end
					9: begin
						arIll['hc] = 1'b1;
						arA1['hc] = 1'sbx;
						arA23['hc] = 1'sbx;
					end
					10: begin
						arIll['hc] = 1'b1;
						arA1['hc] = 1'sbx;
						arA23['hc] = 1'sbx;
					end
					11: begin
						arIll['hc] = 1'b1;
						arA1['hc] = 1'sbx;
						arA23['hc] = 1'sbx;
					end
					default: begin
						arIll['hc] = 1'b1;
						arA1['hc] = 1'sbx;
						arA23['hc] = 1'sbx;
					end
				endcase
			3'b111:
				(* full_case, parallel_case *)
				case (col)
					0: begin
						arIll['hc] = 1'b0;
						arA1['hc] = 'h15b;
						arA23['hc] = 1'sbx;
					end
					1: begin
						arIll['hc] = 1'b1;
						arA1['hc] = 1'sbx;
						arA23['hc] = 1'sbx;
					end
					2: begin
						arIll['hc] = 1'b0;
						arA1['hc] = 'h6;
						arA23['hc] = 'h15a;
					end
					3: begin
						arIll['hc] = 1'b0;
						arA1['hc] = 'h21c;
						arA23['hc] = 'h15a;
					end
					4: begin
						arIll['hc] = 1'b0;
						arA1['hc] = 'h103;
						arA23['hc] = 'h15a;
					end
					5: begin
						arIll['hc] = 1'b0;
						arA1['hc] = 'h1c2;
						arA23['hc] = 'h15a;
					end
					6: begin
						arIll['hc] = 1'b0;
						arA1['hc] = 'h1e3;
						arA23['hc] = 'h15a;
					end
					7: begin
						arIll['hc] = 1'b0;
						arA1['hc] = 'ha;
						arA23['hc] = 'h15a;
					end
					8: begin
						arIll['hc] = 1'b0;
						arA1['hc] = 'h1e2;
						arA23['hc] = 'h15a;
					end
					9: begin
						arIll['hc] = 1'b0;
						arA1['hc] = 'h1c2;
						arA23['hc] = 'h15a;
					end
					10: begin
						arIll['hc] = 1'b0;
						arA1['hc] = 'h1e3;
						arA23['hc] = 'h15a;
					end
					11: begin
						arIll['hc] = 1'b0;
						arA1['hc] = 'hea;
						arA23['hc] = 'h15b;
					end
					default: begin
						arIll['hc] = 1'b1;
						arA1['hc] = 1'sbx;
						arA23['hc] = 1'sbx;
					end
				endcase
		endcase
		(* full_case, parallel_case *)
		case (row86)
			3'b000:
				(* full_case, parallel_case *)
				case (col)
					0: begin
						arIll['hd] = 1'b0;
						arA1['hd] = 'h1c1;
						arA23['hd] = 1'sbx;
					end
					1: begin
						arIll['hd] = 1'b1;
						arA1['hd] = 1'sbx;
						arA23['hd] = 1'sbx;
					end
					2: begin
						arIll['hd] = 1'b0;
						arA1['hd] = 'h6;
						arA23['hd] = 'h1c3;
					end
					3: begin
						arIll['hd] = 1'b0;
						arA1['hd] = 'h21c;
						arA23['hd] = 'h1c3;
					end
					4: begin
						arIll['hd] = 1'b0;
						arA1['hd] = 'h103;
						arA23['hd] = 'h1c3;
					end
					5: begin
						arIll['hd] = 1'b0;
						arA1['hd] = 'h1c2;
						arA23['hd] = 'h1c3;
					end
					6: begin
						arIll['hd] = 1'b0;
						arA1['hd] = 'h1e3;
						arA23['hd] = 'h1c3;
					end
					7: begin
						arIll['hd] = 1'b0;
						arA1['hd] = 'ha;
						arA23['hd] = 'h1c3;
					end
					8: begin
						arIll['hd] = 1'b0;
						arA1['hd] = 'h1e2;
						arA23['hd] = 'h1c3;
					end
					9: begin
						arIll['hd] = 1'b0;
						arA1['hd] = 'h1c2;
						arA23['hd] = 'h1c3;
					end
					10: begin
						arIll['hd] = 1'b0;
						arA1['hd] = 'h1e3;
						arA23['hd] = 'h1c3;
					end
					11: begin
						arIll['hd] = 1'b0;
						arA1['hd] = 'hea;
						arA23['hd] = 'h1c1;
					end
					default: begin
						arIll['hd] = 1'b1;
						arA1['hd] = 1'sbx;
						arA23['hd] = 1'sbx;
					end
				endcase
			3'b001:
				(* full_case, parallel_case *)
				case (col)
					0: begin
						arIll['hd] = 1'b0;
						arA1['hd] = 'h1c1;
						arA23['hd] = 1'sbx;
					end
					1: begin
						arIll['hd] = 1'b0;
						arA1['hd] = 'h1c1;
						arA23['hd] = 1'sbx;
					end
					2: begin
						arIll['hd] = 1'b0;
						arA1['hd] = 'h6;
						arA23['hd] = 'h1c3;
					end
					3: begin
						arIll['hd] = 1'b0;
						arA1['hd] = 'h21c;
						arA23['hd] = 'h1c3;
					end
					4: begin
						arIll['hd] = 1'b0;
						arA1['hd] = 'h103;
						arA23['hd] = 'h1c3;
					end
					5: begin
						arIll['hd] = 1'b0;
						arA1['hd] = 'h1c2;
						arA23['hd] = 'h1c3;
					end
					6: begin
						arIll['hd] = 1'b0;
						arA1['hd] = 'h1e3;
						arA23['hd] = 'h1c3;
					end
					7: begin
						arIll['hd] = 1'b0;
						arA1['hd] = 'ha;
						arA23['hd] = 'h1c3;
					end
					8: begin
						arIll['hd] = 1'b0;
						arA1['hd] = 'h1e2;
						arA23['hd] = 'h1c3;
					end
					9: begin
						arIll['hd] = 1'b0;
						arA1['hd] = 'h1c2;
						arA23['hd] = 'h1c3;
					end
					10: begin
						arIll['hd] = 1'b0;
						arA1['hd] = 'h1e3;
						arA23['hd] = 'h1c3;
					end
					11: begin
						arIll['hd] = 1'b0;
						arA1['hd] = 'hea;
						arA23['hd] = 'h1c1;
					end
					default: begin
						arIll['hd] = 1'b1;
						arA1['hd] = 1'sbx;
						arA23['hd] = 1'sbx;
					end
				endcase
			3'b010:
				(* full_case, parallel_case *)
				case (col)
					0: begin
						arIll['hd] = 1'b0;
						arA1['hd] = 'h1c5;
						arA23['hd] = 1'sbx;
					end
					1: begin
						arIll['hd] = 1'b0;
						arA1['hd] = 'h1c5;
						arA23['hd] = 1'sbx;
					end
					2: begin
						arIll['hd] = 1'b0;
						arA1['hd] = 'hb;
						arA23['hd] = 'h1cb;
					end
					3: begin
						arIll['hd] = 1'b0;
						arA1['hd] = 'hf;
						arA23['hd] = 'h1cb;
					end
					4: begin
						arIll['hd] = 1'b0;
						arA1['hd] = 'h179;
						arA23['hd] = 'h1cb;
					end
					5: begin
						arIll['hd] = 1'b0;
						arA1['hd] = 'h1c6;
						arA23['hd] = 'h1cb;
					end
					6: begin
						arIll['hd] = 1'b0;
						arA1['hd] = 'h1e7;
						arA23['hd] = 'h1cb;
					end
					7: begin
						arIll['hd] = 1'b0;
						arA1['hd] = 'he;
						arA23['hd] = 'h1cb;
					end
					8: begin
						arIll['hd] = 1'b0;
						arA1['hd] = 'h1e6;
						arA23['hd] = 'h1cb;
					end
					9: begin
						arIll['hd] = 1'b0;
						arA1['hd] = 'h1c6;
						arA23['hd] = 'h1cb;
					end
					10: begin
						arIll['hd] = 1'b0;
						arA1['hd] = 'h1e7;
						arA23['hd] = 'h1cb;
					end
					11: begin
						arIll['hd] = 1'b0;
						arA1['hd] = 'ha7;
						arA23['hd] = 'h1c5;
					end
					default: begin
						arIll['hd] = 1'b1;
						arA1['hd] = 1'sbx;
						arA23['hd] = 1'sbx;
					end
				endcase
			3'b011:
				(* full_case, parallel_case *)
				case (col)
					0: begin
						arIll['hd] = 1'b0;
						arA1['hd] = 'h1c9;
						arA23['hd] = 1'sbx;
					end
					1: begin
						arIll['hd] = 1'b0;
						arA1['hd] = 'h1c9;
						arA23['hd] = 1'sbx;
					end
					2: begin
						arIll['hd] = 1'b0;
						arA1['hd] = 'h6;
						arA23['hd] = 'h1c7;
					end
					3: begin
						arIll['hd] = 1'b0;
						arA1['hd] = 'h21c;
						arA23['hd] = 'h1c7;
					end
					4: begin
						arIll['hd] = 1'b0;
						arA1['hd] = 'h103;
						arA23['hd] = 'h1c7;
					end
					5: begin
						arIll['hd] = 1'b0;
						arA1['hd] = 'h1c2;
						arA23['hd] = 'h1c7;
					end
					6: begin
						arIll['hd] = 1'b0;
						arA1['hd] = 'h1e3;
						arA23['hd] = 'h1c7;
					end
					7: begin
						arIll['hd] = 1'b0;
						arA1['hd] = 'ha;
						arA23['hd] = 'h1c7;
					end
					8: begin
						arIll['hd] = 1'b0;
						arA1['hd] = 'h1e2;
						arA23['hd] = 'h1c7;
					end
					9: begin
						arIll['hd] = 1'b0;
						arA1['hd] = 'h1c2;
						arA23['hd] = 'h1c7;
					end
					10: begin
						arIll['hd] = 1'b0;
						arA1['hd] = 'h1e3;
						arA23['hd] = 'h1c7;
					end
					11: begin
						arIll['hd] = 1'b0;
						arA1['hd] = 'hea;
						arA23['hd] = 'h1c9;
					end
					default: begin
						arIll['hd] = 1'b1;
						arA1['hd] = 1'sbx;
						arA23['hd] = 1'sbx;
					end
				endcase
			3'b100:
				(* full_case, parallel_case *)
				case (col)
					0: begin
						arIll['hd] = 1'b0;
						arA1['hd] = 'h1c1;
						arA23['hd] = 1'sbx;
					end
					1: begin
						arIll['hd] = 1'b0;
						arA1['hd] = 'h10f;
						arA23['hd] = 1'sbx;
					end
					2: begin
						arIll['hd] = 1'b0;
						arA1['hd] = 'h6;
						arA23['hd] = 'h299;
					end
					3: begin
						arIll['hd] = 1'b0;
						arA1['hd] = 'h21c;
						arA23['hd] = 'h299;
					end
					4: begin
						arIll['hd] = 1'b0;
						arA1['hd] = 'h103;
						arA23['hd] = 'h299;
					end
					5: begin
						arIll['hd] = 1'b0;
						arA1['hd] = 'h1c2;
						arA23['hd] = 'h299;
					end
					6: begin
						arIll['hd] = 1'b0;
						arA1['hd] = 'h1e3;
						arA23['hd] = 'h299;
					end
					7: begin
						arIll['hd] = 1'b0;
						arA1['hd] = 'ha;
						arA23['hd] = 'h299;
					end
					8: begin
						arIll['hd] = 1'b0;
						arA1['hd] = 'h1e2;
						arA23['hd] = 'h299;
					end
					9: begin
						arIll['hd] = 1'b1;
						arA1['hd] = 1'sbx;
						arA23['hd] = 1'sbx;
					end
					10: begin
						arIll['hd] = 1'b1;
						arA1['hd] = 1'sbx;
						arA23['hd] = 1'sbx;
					end
					11: begin
						arIll['hd] = 1'b1;
						arA1['hd] = 1'sbx;
						arA23['hd] = 1'sbx;
					end
					default: begin
						arIll['hd] = 1'b1;
						arA1['hd] = 1'sbx;
						arA23['hd] = 1'sbx;
					end
				endcase
			3'b101:
				(* full_case, parallel_case *)
				case (col)
					0: begin
						arIll['hd] = 1'b0;
						arA1['hd] = 'h1c1;
						arA23['hd] = 1'sbx;
					end
					1: begin
						arIll['hd] = 1'b0;
						arA1['hd] = 'h10f;
						arA23['hd] = 1'sbx;
					end
					2: begin
						arIll['hd] = 1'b0;
						arA1['hd] = 'h6;
						arA23['hd] = 'h299;
					end
					3: begin
						arIll['hd] = 1'b0;
						arA1['hd] = 'h21c;
						arA23['hd] = 'h299;
					end
					4: begin
						arIll['hd] = 1'b0;
						arA1['hd] = 'h103;
						arA23['hd] = 'h299;
					end
					5: begin
						arIll['hd] = 1'b0;
						arA1['hd] = 'h1c2;
						arA23['hd] = 'h299;
					end
					6: begin
						arIll['hd] = 1'b0;
						arA1['hd] = 'h1e3;
						arA23['hd] = 'h299;
					end
					7: begin
						arIll['hd] = 1'b0;
						arA1['hd] = 'ha;
						arA23['hd] = 'h299;
					end
					8: begin
						arIll['hd] = 1'b0;
						arA1['hd] = 'h1e2;
						arA23['hd] = 'h299;
					end
					9: begin
						arIll['hd] = 1'b1;
						arA1['hd] = 1'sbx;
						arA23['hd] = 1'sbx;
					end
					10: begin
						arIll['hd] = 1'b1;
						arA1['hd] = 1'sbx;
						arA23['hd] = 1'sbx;
					end
					11: begin
						arIll['hd] = 1'b1;
						arA1['hd] = 1'sbx;
						arA23['hd] = 1'sbx;
					end
					default: begin
						arIll['hd] = 1'b1;
						arA1['hd] = 1'sbx;
						arA23['hd] = 1'sbx;
					end
				endcase
			3'b110:
				(* full_case, parallel_case *)
				case (col)
					0: begin
						arIll['hd] = 1'b0;
						arA1['hd] = 'h1c5;
						arA23['hd] = 1'sbx;
					end
					1: begin
						arIll['hd] = 1'b0;
						arA1['hd] = 'h10b;
						arA23['hd] = 1'sbx;
					end
					2: begin
						arIll['hd] = 1'b0;
						arA1['hd] = 'hb;
						arA23['hd] = 'h29d;
					end
					3: begin
						arIll['hd] = 1'b0;
						arA1['hd] = 'hf;
						arA23['hd] = 'h29d;
					end
					4: begin
						arIll['hd] = 1'b0;
						arA1['hd] = 'h179;
						arA23['hd] = 'h29d;
					end
					5: begin
						arIll['hd] = 1'b0;
						arA1['hd] = 'h1c6;
						arA23['hd] = 'h29d;
					end
					6: begin
						arIll['hd] = 1'b0;
						arA1['hd] = 'h1e7;
						arA23['hd] = 'h29d;
					end
					7: begin
						arIll['hd] = 1'b0;
						arA1['hd] = 'he;
						arA23['hd] = 'h29d;
					end
					8: begin
						arIll['hd] = 1'b0;
						arA1['hd] = 'h1e6;
						arA23['hd] = 'h29d;
					end
					9: begin
						arIll['hd] = 1'b1;
						arA1['hd] = 1'sbx;
						arA23['hd] = 1'sbx;
					end
					10: begin
						arIll['hd] = 1'b1;
						arA1['hd] = 1'sbx;
						arA23['hd] = 1'sbx;
					end
					11: begin
						arIll['hd] = 1'b1;
						arA1['hd] = 1'sbx;
						arA23['hd] = 1'sbx;
					end
					default: begin
						arIll['hd] = 1'b1;
						arA1['hd] = 1'sbx;
						arA23['hd] = 1'sbx;
					end
				endcase
			3'b111:
				(* full_case, parallel_case *)
				case (col)
					0: begin
						arIll['hd] = 1'b0;
						arA1['hd] = 'h1c5;
						arA23['hd] = 1'sbx;
					end
					1: begin
						arIll['hd] = 1'b0;
						arA1['hd] = 'h1c5;
						arA23['hd] = 1'sbx;
					end
					2: begin
						arIll['hd] = 1'b0;
						arA1['hd] = 'hb;
						arA23['hd] = 'h1cb;
					end
					3: begin
						arIll['hd] = 1'b0;
						arA1['hd] = 'hf;
						arA23['hd] = 'h1cb;
					end
					4: begin
						arIll['hd] = 1'b0;
						arA1['hd] = 'h179;
						arA23['hd] = 'h1cb;
					end
					5: begin
						arIll['hd] = 1'b0;
						arA1['hd] = 'h1c6;
						arA23['hd] = 'h1cb;
					end
					6: begin
						arIll['hd] = 1'b0;
						arA1['hd] = 'h1e7;
						arA23['hd] = 'h1cb;
					end
					7: begin
						arIll['hd] = 1'b0;
						arA1['hd] = 'he;
						arA23['hd] = 'h1cb;
					end
					8: begin
						arIll['hd] = 1'b0;
						arA1['hd] = 'h1e6;
						arA23['hd] = 'h1cb;
					end
					9: begin
						arIll['hd] = 1'b0;
						arA1['hd] = 'h1c6;
						arA23['hd] = 'h1cb;
					end
					10: begin
						arIll['hd] = 1'b0;
						arA1['hd] = 'h1e7;
						arA23['hd] = 'h1cb;
					end
					11: begin
						arIll['hd] = 1'b0;
						arA1['hd] = 'ha7;
						arA23['hd] = 'h1c5;
					end
					default: begin
						arIll['hd] = 1'b1;
						arA1['hd] = 1'sbx;
						arA23['hd] = 1'sbx;
					end
				endcase
		endcase
	end
	initial _sv2v_0 = 0;
endmodule