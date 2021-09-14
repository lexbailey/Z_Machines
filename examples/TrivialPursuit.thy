theory TrivialPursuit
  imports "Z_Machines.Z_Machine"
begin

lit_vars

enumtype Player = one | two | three | four | five | six

enumtype Colour = blue | pink | yellow | brown | green | orange

definition Colour :: "Colour set" where
"Colour = UNIV"

alphabet LocalScore =
  s :: "Colour set"

record_default LocalScore

alphabet GlobalScore =
  score :: "Player \<Zpfun> LocalScore"

record_default GlobalScore

zoperation AnswerLocal =
  params c \<in> Colour
  pre "c \<in> s"
  update "[s \<leadsto> s \<union> {c}]"

chantype chan1 =
  answer1 :: "Colour"

chantype chan =
  answer :: "Player \<times> Colour"

definition "Answer = operation answer1 AnswerLocal"

definition AnswerGlobal :: "(chan, GlobalScore) htree" where
[code_unfold]: "AnswerGlobal = operation answer (promote_op (\<lambda> p. (score[p])\<^sub>v) AnswerLocal)"

definition "TrivialPursuit = process [\<leadsto>] (loop (Answer \<box> Stop))"

lemma "AnswerGlobal = undefined"
  apply (simp add: AnswerGlobal_def operation_def)
  oops

declare operation_def [code_unfold]
declare wp [code_unfold]
declare unrest [code_unfold]

export_code TrivialPursuit in Haskell module_name TrivialPursuit (string_classes)

term "AnswerLocal c \<Up>\<Up> score[p]"

end