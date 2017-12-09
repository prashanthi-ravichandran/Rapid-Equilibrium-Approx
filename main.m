%% Model definitions

 global Nclefts_FRU Nstates_FRU Nstates_FRUdep Nstates_LType Nstates_RyR NRyRs_per_cleft Nindepstates_LType 
 global NFRU_sim NFRU_scale
 Nclefts_FRU = 4;
 Nstates_FRU = (1+Nclefts_FRU);
 Nstates_FRUdep = 3;

 Nstates_LType = 12;
 Nstates_RyR  = 6;
 NRyRs_per_cleft  = 5;
 Nindepstates_LType = 2;
 NFRU_sim_low  = 250;
 NFRU_scale_low = 50.0; % ratio of 12500/NFRU_sim_low
 NFRU_sim_high = 250;
 NFRU_scale_high = 50.0; % ratio of 12500/NFRU_sim_high
 
 NFRU_sim_max = 250;
 
 NFRU_sim=NFRU_sim_high;
 NFRU_scale = NFRU_scale_high;
% Specify simulation parameters
num_beats  = 5;
freq       = 1;
ISI        = 1000/freq; %ms
time_start = 0.0;
time_end = num_beats*ISI;
%time_end = 100;
% Time step has been decreased to match tauxfer
tstep    = 0.01;

% AP Clamp
global pulse_duration pulse_amplitude  period shift
pulse_duration = 0.5;
pulse_amplitude = -100.0;
period = 1000.0;
shift = 5.0;

% Define parameters for voltage clamp.
 global vclamp_flag vclamp_duration vclamp_set vclamp_shift vclamp_hold vclamp_period
 vclamp_flag = 1;
 vclamp_duration = 200.0;
 vclamp_set      =   0.0;
 vclamp_shift    =  10.0;
 vclamp_hold     =  -100.0;
 vclamp_period   = 1000.0;
 
% Specify input and output files
% Define input files
 ic_clamp = 1;
 input_dir = 'ic/vclamp';
 ic_states_file = strcat(input_dir,'/','ic_states_NVC.txt');
 ic_FRU_file = strcat(input_dir, '/','ic_FRU_NVC.txt');
 ic_LCh_file = strcat(input_dir,'/','ic_LCh_NVC.txt');
 ic_RyR_file = strcat(input_dir,'/','ic_RyR_NVC.txt');
 ic_Ito2_file = strcat(input_dir,'/','ic_Ito2_NVC.txt');
 
 % Define output files
 output_dir           = 'vclamp';
 mkdir(output_dir);
 filenumber           = 1;
 output_states_file   = strcat(output_dir,'/','states', num2str(filenumber),'.txt');
 output_currents_file = strcat(output_dir,'/','currents', num2str(filenumber),'.txt');
 output_otherstates_file = strcat(output_dir,'/','otherstates', num2str(filenumber),'.txt');
 fileID = fopen(output_states_file, 'w');
 fprintf(fileID, '%s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s \n', ...
		'Time','V','mNa','hNa','jNa','Nai','Ki','Cai','CaNSR','xKs', ...
		'LTRPNCa','HTRPNCa','C0Kv43','C1Kv43','C2Kv43','C3Kv43','OKv43','CI0Kv43','CI1Kv43','CI2Kv43', ...
		'CI3Kv43','OIKv43','C0Kv14','C1Kv14','C2Kv14','C3Kv14','OKv14','CI0Kv14','CI1Kv14','CI2Kv14', ...
		'CI3Kv14','OIKv14','CaToT','C1Herg','C2Herg','C3Herg','OHerg','IHerg');
 fclose(fileID);  
 fileID = fopen(output_currents_file, 'w');
 fprintf(fileID, '%s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s \n', ...
		'Time','INa','IKr','IKs','Ito1','IK1','IKp','INaCa','INaK','IpCa', ...
		'ICab','INab','ICa','JDHPR','Jup','Jtrpn','Jtr','Jxfer','IKv43','IKv14', ...
		'IKv14_K','IKv14_Na','Ito2','Istim','Itot');
 fclose(fileID);
 
 fileID = fopen(output_otherstates_file, 'w');
 
 fprintf(fileID, '%s %s %s %s %s %s %s %s %s %s \n', ...
			'Time','CaSSavg','CaJSRavg','JRyRtot','PRyR_open','PRyR_ready','PNorm_mode','PnotVinact','PLType_open','PIto2_open');
 fclose(fileID);
 
%% Initialize state variables and gates
onez = gpuArray.ones(NFRU_sim,1,'double');
index_V = 1;
index_Cai       = 7;
index_CaNSR     = 8;
index_CaSSavg  = 1;
index_CaJSRavg = 2;
index_JRyRtot  = 3;
index_PRyR_Open = 4;
index_PRyR_ready = 5;
index_PNorm_Mode = 6;
index_PVinact = 7;
index_PLtype_Open = 8;
index_PIto2_Open = 9;

if(ic_clamp)
    [state, FRU_state, LType_state, RyR_state, Ito2_state] = initialize(ic_states_file, ic_FRU_file, ic_LCh_file,ic_RyR_file,ic_Ito2_file);
else
    state = [ -100.0100   1.21087e-4    0.999484    0.999480      10.0000     133.24    1.11074e-4   0.72873    0.104829e-3    0.1003...
                 0.9780      0.968277     0.0133601   0.691875e-4   0.159092e-6 0.0     0.0153235    0.00271424   0.243515e-3 ...
                 0.115007e-4    0.163239e-6 0.824239    0.0522865   0.00124396  0.131359e-4 0.522383e-7 0.118010    0.003334011 0.684631e-3...
                 0.136717e-3 0.451249e-4 0.6810488214E+01   0.990   0.008   0.002   0.0     0.0];
    LType_state = zeros(NFRU_sim, Nclefts_FRU,Nindepstates_LType);
    FRU_state = horzcat( 0.728921.*ones(NFRU_sim,1), 0.111074e-3.*ones(NFRU_sim, Nclefts_FRU));
    RyR_state = ones(NFRU_sim, Nclefts_FRU, NRyRs_per_cleft);
    Ito2_state = ones(NFRU_sim, Nclefts_FRU);
    LType_state(:,:,1) = ones(NFRU_sim, Nclefts_FRU);
    LType_state(:,:,2) = 2.*ones(NFRU_sim, Nclefts_FRU);  
end

LCC1 = LType_state(:,1,1).*onez;
LCC2 = LType_state(:,2,1).*onez;
LCC3 = LType_state(:,3,1).*onez;
LCC4 = LType_state(:,4,1).*onez;

Y1 = LType_state(:,1,2).*onez;
Y2 = LType_state(:,2,2).*onez;
Y3 = LType_state(:,3,2).*onez;
Y4 = LType_state(:,4,2).*onez;

Ito2_1 = Ito2_state(:,1).*onez;
Ito2_2 = Ito2_state(:,2).*onez;
Ito2_3 = Ito2_state(:,3).*onez;
Ito2_4 = Ito2_state(:,4).*onez;

RyR11 = RyR_state(:,1,1).*onez;
RyR12 = RyR_state(:,1,2).*onez;
RyR13 = RyR_state(:,1,3).*onez;
RyR14 = RyR_state(:,1,4).*onez;
RyR15 = RyR_state(:,1,5).*onez;

RyR21 = RyR_state(:,2,1).*onez;
RyR22 = RyR_state(:,2,2).*onez;
RyR23 = RyR_state(:,2,3).*onez;
RyR24 = RyR_state(:,2,4).*onez;
RyR25 = RyR_state(:,2,5).*onez;

RyR31 = RyR_state(:,3,1).*onez;
RyR32 = RyR_state(:,3,2).*onez;
RyR33 = RyR_state(:,3,3).*onez;
RyR34 = RyR_state(:,3,4).*onez;
RyR35 = RyR_state(:,3,5).*onez;

RyR41 = RyR_state(:,4,1).*onez;
RyR42 = RyR_state(:,4,2).*onez;
RyR43 = RyR_state(:,4,3).*onez;
RyR44 = RyR_state(:,4,4).*onez;
RyR45 = RyR_state(:,4,5).*onez;
    
CaJSR   = FRU_state(:,1).*onez;
[CaSS1, CaSS2, CaSS3, CaSS4] = arrayfun(@calc_local_states, state(index_V).*onez,state(index_Cai).*onez,CaJSR, LCC1,LCC2, LCC3,LCC4,Y1, Y2, Y3, Y4,RyR11, RyR12, RyR13, RyR14, RyR15,...
                                                         RyR21, RyR22, RyR23, RyR24, RyR25, RyR31, RyR32, RyR33, RyR34, RyR35, RyR41, RyR42, RyR43, RyR44, RyR45);

% Set up arrays to store simulation data
global N Ncur Nother
N = 37;
Ncur = 24;
Nother = 12;
current     = zeros(Ncur,1);
otherstates = zeros(Nother,1);
Fstate = zeros(N,1);
ii = 1;
saveinterval = 1;
fprintf('Time \t Voltage \t Cai\n');
%% Main loop
for time = time_start:tstep:time_end
    index_V = 1;
    if(mod(time,1)==0)
        fprintf('%g \t %g \t %g \n',time, state(1), state(7));
    end
     if(vclamp_flag == 1)
      time_vclamp_on = floor((time-vclamp_shift)/vclamp_period)*vclamp_period;
	  time_vclamp_off = time_vclamp_on + vclamp_duration;
          if (((time-vclamp_shift) >= time_vclamp_on)  && (time_vclamp_on>=0.0) && ((time-vclamp_shift) < time_vclamp_off)) 
              % Change the ramp time to 5 ms
             ramp = (((time-vclamp_shift)-time_vclamp_on)/2.0)*(vclamp_set-vclamp_hold) + vclamp_hold;
                  if (vclamp_hold<=vclamp_set) 
                    state(index_V) = min(vclamp_set,ramp); % depol.  steps
                  else 
                    state(index_V) = max(vclamp_set,ramp); % hyperpol. steps
                  end
               %state(index_V) = vclamp_set;
          else 
              if (((time-vclamp_shift)<time_vclamp_on)||(time_vclamp_on<0.0)) 
                  state(index_V) = vclamp_hold;
              else 
                   ramp = vclamp_set +((time_vclamp_on + vclamp_duration-(time-vclamp_shift))/2.0)*(vclamp_set-vclamp_hold);
                   if (vclamp_hold<=vclamp_set) 
                      state(index_V) = max(vclamp_hold,ramp); % depol. step
                   else 
                      state(index_V) = min(vclamp_hold,ramp); % hyper. step
                   end
              end
                %state(index_V) = vclamp_hold;
          end
     end
     
     % Calculate the derivatives
%      FRUdep_states(1) = state(1);
%      FRUdep_states(2) = state(7); 
%      FRUdep_states(3) = state(8);
      
     %[dFRU_state, Jxfer, Jtr, ICa, Ito2]  = calc_fru_local(FRUdep_states,FRU_state, Ltype_state, RyR_state,Ito2_state);
     % Calculate  the state derivatives    
     
     [dCaJSR, Jtr_local,ICa_local, Ito2_local,Jxfer_local] = arrayfun(@calc_dCaJSR,state(index_V).*onez,state(index_Cai).*onez, state(index_CaNSR).*onez, CaJSR, CaSS1,CaSS2, CaSS3, CaSS4, RyR11, RyR12, RyR13, RyR14, RyR15,...
                                     RyR21, RyR22, RyR23, RyR24, RyR25, RyR31, RyR32, RyR33, RyR34, RyR35, RyR41, RyR42,...
                                     RyR43, RyR44, RyR45, LCC1, LCC2,LCC3, LCC4, Y1, Y2, Y3, Y4, Ito2_1, Ito2_2, Ito2_3, Ito2_4);
     Jtr   = NFRU_scale*gather(sum(Jtr_local));
     ICa   = NFRU_scale*gather(sum(ICa_local));
     Ito2  = NFRU_scale*gather(sum(Ito2_local));
     Jxfer = NFRU_scale*gather(sum(Jxfer_local));                            
     [state, Fstate, current]             = calc_derivative(time, state, current, Jxfer, Jtr, ICa, Ito2);
     
  
     % Write current states into file
     if(mod(time,1 == 0))
         fileID = fopen(output_states_file, 'a');
         fprintf(fileID, '%d %s', time,' ');
         dlmwrite(output_states_file, state,'-append','delimiter',' ')
         fclose(fileID);

        % Populate currents file and otherstates file
        fileID = fopen(output_currents_file, 'a');
        fprintf(fileID,'%d %s',time,' ');
        dlmwrite(output_currents_file, current','-append','delimiter',' ')
        fclose(fileID);
        [N11,N12,N13,N14,N15,N16,N17,N18] = arrayfun(@RyR_occupancy,RyR11, RyR12, RyR13, RyR14, RyR15);
        [N21,N22,N23,N24,N25,N26,N27,N28] = arrayfun(@RyR_occupancy,RyR21, RyR22, RyR23, RyR24, RyR25);
        [N31,N32,N33,N34,N35,N36,N37,N38] = arrayfun(@RyR_occupancy,RyR31, RyR32, RyR33, RyR34, RyR35);
        [N41,N42,N43,N44,N45,N46,N47,N48] = arrayfun(@RyR_occupancy,RyR41, RyR42, RyR43, RyR44, RyR45);
        [LO1, LN1, LI1, LO2, LN2, LI2, LO3,LN3, LI3, LO4, LN4, LI4] = arrayfun(@LType_open_prob, LCC1, LCC2, LCC3, LCC4, Y1, Y2, Y3, Y4);
        [I1, I2, I3, I4] = arrayfun(@Ito2_open_prob, Ito2_1, Ito2_2,Ito2_3, Ito2_4);
        
        N1 = N11 + N21 + N31 + N41;
        N2 = N12 + N22 + N32 + N42;
        N3 = N13 + N23 + N33 + N43;
        N4 = N14 + N24 + N34 + N44;
        N5 = N15 + N25 + N35 + N45;
        N6 = N16 + N26 + N36 + N46;
        N7 = N17 + N27 + N37 + N47;
        N8 = N18 + N28 + N38 + N48;
        RyRoccupancies = zeros(1,8);
        RyR_occupancies(1) = gather(sum(N1));
        RyR_occupancies(2) = gather(sum(N2));
        RyR_occupancies(3) = gather(sum(N3));
        RyR_occupancies(4) = gather(sum(N4));
        RyR_occupancies(5) = gather(sum(N5));
        RyR_occupancies(6) = gather(sum(N6));
        RyR_occupancies(7) = gather(sum(N7));
        RyR_occupancies(8) = gather(sum(N8));
        P_RyR_occupancies = RyR_occupancies./(NFRU_sim*Nclefts_FRU*NRyRs_per_cleft);
        [JRyRtot] = arrayfun(@Calc_JRyR,CaJSR, CaSS1, CaSS2, CaSS3, CaSS4,RyR11, RyR12, RyR13, RyR14, RyR15, RyR21, RyR22, RyR23, RyR24, RyR25, RyR31, RyR32,RyR33,...
                               RyR34, RyR35, RyR41, RyR42, RyR43, RyR44, RyR45);
        VSS= (0.5*0.2*2.03e-12); % subspace volume (uL)
        Vmyo= 25.84e-6; % myoplasmic volume (uL)
        otherstates(index_CaSSavg)  = (gather(sum(CaSS1)) + gather(sum(CaSS2)) + gather(sum(CaSS3)) +  gather(sum(CaSS4)))/(NFRU_sim*Nclefts_FRU);
        otherstates(index_CaJSRavg) = gather(sum(CaJSR))/NFRU_sim;
        otherstates(index_JRyRtot) = gather(sum(JRyRtot))*NFRU_scale*VSS/Vmyo;
        otherstates(index_PRyR_Open)  = (RyR_occupancies(3) + RyR_occupancies(4) + RyR_occupancies(7))/(NRyRs_per_cleft*Nclefts_FRU*NFRU_sim);
        otherstates(index_PRyR_ready)  = (RyR_occupancies(1) + RyR_occupancies(2))/(NRyRs_per_cleft*Nclefts_FRU*NFRU_sim);
        otherstates(index_PNorm_Mode) = (gather(sum(LN1)) + gather(sum(LN2)) + gather(sum(LN3)) + gather(sum(LN4)))/(NFRU_sim*Nclefts_FRU);
        otherstates(index_PVinact) = (gather(sum(LI1)) + gather(sum(LI2)) + gather(sum(LI3)) + gather(sum(LI4)))/(NFRU_sim*Nclefts_FRU)/(NFRU_sim*Nclefts_FRU);
        otherstates(index_PLtype_Open) = (gather(sum(LO1)) + gather(sum(LO2)) + gather(sum(LO3)) + gather(sum(LO4)))/(NFRU_sim*Nclefts_FRU);
        otherstates(index_PIto2_Open) = (gather(sum(I1)) + gather(sum(I2)) + gather(sum(I3)) + gather(sum(I4)))/(NFRU_sim*Nclefts_FRU);
        fileID = fopen(output_otherstates_file,'a');
        fprintf(fileID, '%d %s', time,' ');
        dlmwrite(output_otherstates_file,otherstates' ,'-append','delimiter',' ')
        fclose(fileID);
     end

    % Determine stochastic switching of the gates
    
           % Perform montecarlo sim
       
    rand1  = gpuArray.rand(NFRU_sim,1,'single');
    rand2  = gpuArray.rand(NFRU_sim,1,'single');
    rand3  = gpuArray.rand(NFRU_sim,1,'single');
    rand4  = gpuArray.rand(NFRU_sim,1,'single');
    rand5  = gpuArray.rand(NFRU_sim,1,'single');
    rand6  = gpuArray.rand(NFRU_sim,1,'single');
    rand7  = gpuArray.rand(NFRU_sim,1,'single');
    rand8  = gpuArray.rand(NFRU_sim,1,'single');
    rand9  = gpuArray.rand(NFRU_sim,1,'single');
    rand10 = gpuArray.rand(NFRU_sim,1,'single');
    rand11 = gpuArray.rand(NFRU_sim,1,'single');
    rand12 = gpuArray.rand(NFRU_sim,1,'single');

    rand13  = gpuArray.rand(NFRU_sim,1,'single');
    rand14  = gpuArray.rand(NFRU_sim,1,'single');
    rand15  = gpuArray.rand(NFRU_sim,1,'single');
    rand16  = gpuArray.rand(NFRU_sim,1,'single');
    rand17  = gpuArray.rand(NFRU_sim,1,'single');
    rand18  = gpuArray.rand(NFRU_sim,1,'single');
    rand19  = gpuArray.rand(NFRU_sim,1,'single');
    rand20 = gpuArray.rand(NFRU_sim,1,'single');
    rand21  = gpuArray.rand(NFRU_sim,1,'single');
    rand22 = gpuArray.rand(NFRU_sim,1,'single');
    rand23 = gpuArray.rand(NFRU_sim,1,'single');
    rand24 = gpuArray.rand(NFRU_sim,1,'single');
    rand25 = gpuArray.rand(NFRU_sim,1,'single');

    rand26  = gpuArray.rand(NFRU_sim,1,'single');
    rand27  = gpuArray.rand(NFRU_sim,1,'single');
    rand28  = gpuArray.rand(NFRU_sim,1,'single');
    rand29  = gpuArray.rand(NFRU_sim,1,'single');
    rand30  = gpuArray.rand(NFRU_sim,1,'single');
    rand31  = gpuArray.rand(NFRU_sim,1,'single');
    rand32  = gpuArray.rand(NFRU_sim,1,'single');
    rand33 = gpuArray.rand(NFRU_sim,1,'single');
    rand34  = gpuArray.rand(NFRU_sim,1,'single');
    rand35 = gpuArray.rand(NFRU_sim,1,'single');
    rand36 = gpuArray.rand(NFRU_sim,1,'single');
    rand37 = gpuArray.rand(NFRU_sim,1,'single');

    rand38  = gpuArray.rand(NFRU_sim,1,'single');
    rand39  = gpuArray.rand(NFRU_sim,1,'single');
    rand40  = gpuArray.rand(NFRU_sim,1,'single');
    rand41  = gpuArray.rand(NFRU_sim,1,'single');
    rand42  = gpuArray.rand(NFRU_sim,1,'single');
    rand43  = gpuArray.rand(NFRU_sim,1,'single');
    rand44  = gpuArray.rand(NFRU_sim,1,'single');
    rand45 = gpuArray.rand(NFRU_sim,1,'single');
    rand46  = gpuArray.rand(NFRU_sim,1,'single');
    rand47 = gpuArray.rand(NFRU_sim,1,'single');
    rand48 = gpuArray.rand(NFRU_sim,1,'single');
    rand49 = gpuArray.rand(NFRU_sim,1,'single');
    rand50 = gpuArray.rand(NFRU_sim,1,'single');

    rand51  = gpuArray.rand(NFRU_sim,1,'single');
    rand52  = gpuArray.rand(NFRU_sim,1,'single');
    rand53  = gpuArray.rand(NFRU_sim,1,'single');
    rand54  = gpuArray.rand(NFRU_sim,1,'single');
    rand55  = gpuArray.rand(NFRU_sim,1,'single');
    rand56  = gpuArray.rand(NFRU_sim,1,'single');
    rand57  = gpuArray.rand(NFRU_sim,1,'single');
    rand58  = gpuArray.rand(NFRU_sim,1,'single');
    rand59  = gpuArray.rand(NFRU_sim,1,'single');
    rand60 = gpuArray.rand(NFRU_sim,1,'single');
    rand61 = gpuArray.rand(NFRU_sim,1,'single');
    rand62 = gpuArray.rand(NFRU_sim,1,'single');

    rand63  = gpuArray.rand(NFRU_sim,1,'single');
    rand64  = gpuArray.rand(NFRU_sim,1,'single');
    rand65  = gpuArray.rand(NFRU_sim,1,'single');
    rand66  = gpuArray.rand(NFRU_sim,1,'single');
    rand67  = gpuArray.rand(NFRU_sim,1,'single');
    rand68  = gpuArray.rand(NFRU_sim,1,'single');
    rand69  = gpuArray.rand(NFRU_sim,1,'single');
    rand70 = gpuArray.rand(NFRU_sim,1,'single');
    rand71  = gpuArray.rand(NFRU_sim,1,'single');
    rand72 = gpuArray.rand(NFRU_sim,1,'single');

    tempdt = tstep.*onez;
    V = state(index_V);
    [LCC1, Y1, Ito2_1] = arrayfun( @new_Ltype, tempdt,V.*onez,CaSS1, LCC1, Y1, Ito2_1, rand1, rand2, rand3);
    [LCC2, Y2, Ito2_2] = arrayfun( @new_Ltype, tempdt,V.*onez,CaSS2, LCC2, Y2, Ito2_2, rand4, rand5, rand6);
    [LCC3, Y3, Ito2_3] = arrayfun( @new_Ltype, tempdt,V.*onez,CaSS3, LCC3, Y3, Ito2_3, rand7, rand8, rand9);
    [LCC4, Y4, Ito2_4] = arrayfun( @new_Ltype, tempdt,V.*onez,CaSS4, LCC4, Y4, Ito2_4, rand10, rand11, rand12);

    [RyR11] = arrayfun( @switch_RyR, tempdt, CaSS1, RyR11,rand13, rand14, rand15);
    [RyR12] = arrayfun( @switch_RyR, tempdt, CaSS1, RyR12,rand16, rand17, rand18);
    [RyR13] = arrayfun( @switch_RyR, tempdt, CaSS1, RyR13,rand19, rand20, rand21);
    [RyR14] = arrayfun( @switch_RyR, tempdt, CaSS1, RyR14, rand22, rand23, rand24);
    [RyR15] = arrayfun( @switch_RyR, tempdt, CaSS1, RyR15, rand25, rand26, rand27);

    [RyR21] = arrayfun( @switch_RyR, tempdt, CaSS2, RyR21,rand28, rand29, rand30);
    [RyR22] = arrayfun( @switch_RyR, tempdt, CaSS2, RyR22,rand31, rand32, rand33);
    [RyR23] = arrayfun( @switch_RyR, tempdt, CaSS2, RyR23,rand34, rand35, rand36);
    [RyR24] = arrayfun( @switch_RyR, tempdt, CaSS2, RyR24, rand37, rand38, rand39);
    [RyR25] = arrayfun( @switch_RyR, tempdt, CaSS2, RyR25, rand40, rand41, rand42);

    [RyR31] = arrayfun( @switch_RyR, tempdt, CaSS3, RyR31,rand43, rand44, rand45);
    [RyR32] = arrayfun( @switch_RyR, tempdt, CaSS3, RyR32,rand46, rand47, rand48);
    [RyR33] = arrayfun( @switch_RyR, tempdt, CaSS3, RyR33,rand49, rand50, rand51);
    [RyR34] = arrayfun( @switch_RyR, tempdt, CaSS3, RyR34, rand52, rand53, rand54);
    [RyR35] = arrayfun( @switch_RyR, tempdt, CaSS3, RyR35, rand55, rand56, rand57);

    [RyR41] = arrayfun( @switch_RyR, tempdt, CaSS4, RyR41,rand58, rand59, rand60);
    [RyR42] = arrayfun( @switch_RyR, tempdt, CaSS4, RyR42,rand61, rand62, rand63);
    [RyR43] = arrayfun( @switch_RyR, tempdt, CaSS4, RyR43,rand64, rand65, rand66);
    [RyR44] = arrayfun( @switch_RyR, tempdt, CaSS4, RyR44, rand67, rand68, rand69);
    [RyR45] = arrayfun( @switch_RyR, tempdt, CaSS4, RyR45, rand70, rand71, rand72);
    
    % Euler integration
   
    state = state + (tstep.*Fstate);
    CaJSR = CaJSR + tstep.*dCaJSR;
    % Use rapid equilibrium assumption to update local concentrations
    [CaSS1, CaSS2, CaSS3, CaSS4] = arrayfun(@calc_local_states, state(index_V).*onez,state(index_Cai).*onez,CaJSR, LCC1,LCC2, LCC3,LCC4,Y1, Y2, Y3, Y4,RyR11, RyR12, RyR13, RyR14, RyR15,...
                                                         RyR21, RyR22, RyR23, RyR24, RyR25, RyR31, RyR32, RyR33, RyR34, RyR35, RyR41, RyR42, RyR43, RyR44, RyR45);
 
    %FRU_state = FRU_state + (tstep.*dFRU_state);

end