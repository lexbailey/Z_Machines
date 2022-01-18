section \<open> Dwarf Signal \<close>

theory DwarfSignal
  imports "Z_Machines.Z_Machine"
begin                

subsection \<open> State Space \<close>

enumtype LampId = L1 | L2 | L3

type_synonym Signal = "LampId set"

enumtype ProperState = dark | stop | warning | drive

definition "ProperState = {dark, stop, warning, drive}"

fun signalLamps :: "ProperState \<Rightarrow> LampId set" where
"signalLamps dark = {}" |
"signalLamps stop = {L1, L2}" |
"signalLamps warning = {L1, L3}" |
"signalLamps drive = {L2, L3}"

text \<open> Could we have separate processes for the actual lamp and its controller? We would then
  try to verify that the controller preserves the lamp-based safety properties. The current
  set up doesn't preserve them. \<close>

zstore Dwarf = 
  last_proper_state :: "ProperState"
  turn_off :: "LampId set"
  turn_on  :: "LampId set"
  last_state :: "Signal"
  current_state :: "Signal"
  desired_proper_state :: "ProperState"
  where 
    "(current_state - turn_off) \<union> turn_on = signalLamps desired_proper_state"
    "turn_on \<inter> turn_off = {}"

zoperation SetNewProperState =
  over Dwarf
  params st\<in>"ProperState - {last_proper_state}"
  pre "current_state = signalLamps desired_proper_state"
  update "[last_proper_state\<Zprime> = desired_proper_state
          ,turn_off\<Zprime> = current_state - signalLamps st
          ,turn_on\<Zprime> = signalLamps st - current_state
          ,last_state\<Zprime> = current_state
          ,desired_proper_state\<Zprime> = st]"

zoperation TurnOff =
  over Dwarf
  params l\<in>turn_off 
  update "[turn_off\<Zprime> = turn_off - {l}
          ,turn_on\<Zprime> = turn_on - {l}
          ,last_state\<Zprime> = current_state
          ,current_state\<Zprime> = current_state - {l}]"

zoperation TurnOn =
  over Dwarf
  params l\<in>turn_on
  update "[turn_off\<Zprime> = turn_off - {l}
          ,turn_on\<Zprime> = turn_on - {l}
          ,last_state\<Zprime> = current_state
          ,current_state\<Zprime> = current_state \<union> {l}]"

zoperation Shine =
  over Dwarf
  params l\<in>"{current_state}"

definition Init :: "Dwarf subst" where
  [z_defs]:
  "Init = 
  [ last_proper_state \<leadsto> stop
  , turn_off \<leadsto> {}
  , turn_on \<leadsto> {}
  , last_state \<leadsto> signalLamps stop
  , current_state \<leadsto> signalLamps stop
  , desired_proper_state \<leadsto> stop ]"

zmachine DwarfSignal = 
  init Init
  operations SetNewProperState TurnOn TurnOff Shine

animate DwarfSignal

zexpr NeverShowAll 
  is "Dwarf_inv \<and> current_state \<noteq> {L1, L2, L3}"

zexpr MaxOneLampChange
  is "Dwarf_inv \<and> (\<exists> l. current_state - last_state = {l} \<or> last_state - current_state = {l} \<or> last_state = current_state)"

zexpr ForbidStopToDrive
  is "Dwarf_inv \<and> (last_proper_state = stop \<longrightarrow> desired_proper_state \<noteq> drive)"

zexpr DarkOnlyToStop
  is "Dwarf_inv \<and> (last_proper_state = dark \<longrightarrow> desired_proper_state = stop)"

zexpr DarkOnlyFromStop
  is "Dwarf_inv \<and> (desired_proper_state = dark \<longrightarrow> last_proper_state = stop)"

zexpr DwarfReq
  is "NeverShowAll \<and> MaxOneLampChange \<and> ForbidStopToDrive \<and> DarkOnlyToStop \<and> DarkOnlyFromStop"

lemma "Init establishes Dwarf_inv"
  by z_wlp_auto

lemma "(SetNewProperState p) preserves Dwarf_inv"
  by z_wlp_auto

lemma "(SetNewProperState p) preserves NeverShowAll"
  by z_wlp_auto

lemma "(SetNewProperState p) preserves MaxOneLampChange"
  by z_wlp_auto

lemma "(SetNewProperState p) preserves ForbidStopToDrive"
  apply z_wlp_auto
  quickcheck
  oops

lemma "TurnOn l preserves Dwarf_inv"
  by z_wlp_auto

lemma "TurnOff l preserves Dwarf_inv"
  by z_wlp_auto  


(*
definition "CheckReq = 
  (\<questiondown>\<not> @NeverShowAll? \<Zcomp> violation!(STR ''NeverShowAll'') \<rightarrow> Skip) \<box>
  (\<questiondown>\<not> @MaxOneLampChange? \<Zcomp> violation!(STR ''MaxOneLampChange'') \<rightarrow> Skip) \<box>
  (\<questiondown>\<not> @ForbidStopToDrive? \<Zcomp> violation!(STR ''ForbidStopToDrive'') \<rightarrow> Skip) \<box>
  (\<questiondown>\<not> @DarkOnlyToStop? \<Zcomp> violation!(STR ''DarkOnlyToStop'') \<rightarrow> Skip) \<box>
  (\<questiondown>\<not> @DarkOnlyFromStop? \<Zcomp> violation!(STR ''DarkOnlyFromStop'') \<rightarrow> Skip)"
*)

end