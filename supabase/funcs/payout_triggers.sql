            tgname            |                                                                                                  def                                                                                                   
------------------------------+--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 RI_ConstraintTrigger_c_38474 | CREATE CONSTRAINT TRIGGER "RI_ConstraintTrigger_c_38474" AFTER INSERT ON public.transactions FROM bundles NOT DEFERRABLE INITIALLY IMMEDIATE FOR EACH ROW EXECUTE FUNCTION "RI_FKey_check_ins"()
 RI_ConstraintTrigger_c_38475 | CREATE CONSTRAINT TRIGGER "RI_ConstraintTrigger_c_38475" AFTER UPDATE ON public.transactions FROM bundles NOT DEFERRABLE INITIALLY IMMEDIATE FOR EACH ROW EXECUTE FUNCTION "RI_FKey_check_upd"()
 RI_ConstraintTrigger_c_38479 | CREATE CONSTRAINT TRIGGER "RI_ConstraintTrigger_c_38479" AFTER INSERT ON public.transactions FROM offers NOT DEFERRABLE INITIALLY IMMEDIATE FOR EACH ROW EXECUTE FUNCTION "RI_FKey_check_ins"()
 RI_ConstraintTrigger_c_38480 | CREATE CONSTRAINT TRIGGER "RI_ConstraintTrigger_c_38480" AFTER UPDATE ON public.transactions FROM offers NOT DEFERRABLE INITIALLY IMMEDIATE FOR EACH ROW EXECUTE FUNCTION "RI_FKey_check_upd"()
 RI_ConstraintTrigger_a_38496 | CREATE CONSTRAINT TRIGGER "RI_ConstraintTrigger_a_38496" AFTER DELETE ON public.transactions FROM payouts_v2 NOT DEFERRABLE INITIALLY IMMEDIATE FOR EACH ROW EXECUTE FUNCTION "RI_FKey_noaction_del"()
 RI_ConstraintTrigger_a_38497 | CREATE CONSTRAINT TRIGGER "RI_ConstraintTrigger_a_38497" AFTER UPDATE ON public.transactions FROM payouts_v2 NOT DEFERRABLE INITIALLY IMMEDIATE FOR EACH ROW EXECUTE FUNCTION "RI_FKey_noaction_upd"()
 trg_after_transaction_insert | CREATE TRIGGER trg_after_transaction_insert AFTER INSERT ON public.transactions FOR EACH ROW EXECUTE FUNCTION create_or_update_payouts_for_transaction()
(7 rows)

