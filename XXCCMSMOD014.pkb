CREATE OR REPLACE PACKAGE BODY xxccms.xxccms_employeesync_pkg
AS

----------------------------------------------------------------------------------
--GLOBAL CONSTANTS
--------------------------------------------------------------------------------
   gc_request_id                          NUMBER
                                                := fnd_global.conc_request_id;
   gc_program_name                        VARCHAR2 (30)
                                               := 'XXCCMS_EMPLOYEE_INTERFACE';
   gc_return_true_b              CONSTANT BOOLEAN         := TRUE;
   gc_return_false_b             CONSTANT BOOLEAN         := FALSE;
   gc_error_code_no_data_found   CONSTANT NUMBER          := -1;
   gc_error_code_others          CONSTANT NUMBER          := -3;
   gc_title_lookup               CONSTANT VARCHAR2 (10)   := 'TITLE';
   gc_sex_lookup                 CONSTANT VARCHAR2 (10)   := 'SEX';
--------------------------------------------------------------------------------
 --GLOBAL VARIABLES
--------------------------------------------------------------------------------
   g_all_attr1                            VARCHAR2 (150)  := NULL;
   g_all_attr2                            VARCHAR2 (150)  := NULL;
   g_all_attr3                            VARCHAR2 (150)  := NULL;
   g_ass_success                          VARCHAR2 (20);
   g_success                              VARCHAR2 (20);
   g_effective_date                       DATE;
   g_error_column_value                   VARCHAR2 (2000);
   g_bookmark                             VARCHAR2 (1000);
   g_linecount                            NUMBER          := 0;
   g_procedure_name                       VARCHAR2 (32);
   g_ass_eff_start_date                   DATE;
   g_assign_num_error                     NUMBER;
   g_location_id                          NUMBER;
   g_job_id                               NUMBER;
   g_organization_id                      NUMBER;
   g_record_valid                         BOOLEAN;
   g_datetrack_update_mode                VARCHAR2 (20);
   g_sys_per_type                         VARCHAR2 (40);
   g_user_per_type                        VARCHAR2 (40);
   g_emp_flag                             VARCHAR2 (10);
   g_new_emp_cwk_flag                     VARCHAR2 (10);
   g_per_service_id                       NUMBER;
   g_latest_start_date                    DATE;
   g_business_group_id                    NUMBER (10);
   g_last_name                            VARCHAR2 (200);
   g_gender                               VARCHAR2 (5);
   g_person_type_id                       NUMBER (10);
   g_dob                                  DATE;
   g_employee_number                      VARCHAR2 (40);
   g_first_name                           VARCHAR2 (200);
   g_title                                VARCHAR2 (10);
   g_person_id                            NUMBER (10);
   g_assignment_id                        NUMBER (10);
   g_per_object_version_number            NUMBER (10);
   g_asg_object_version_number            NUMBER (10);
   g_per_effective_start_date             DATE;
   g_per_effective_end_date               DATE;
   g_assignment_number                    VARCHAR2 (20);
   g_npw_number                           VARCHAR2 (20);
   g_object_version_number                NUMBER (20);
   g_effective_start_date                 DATE;
   g_effective_end_date                   DATE;
   g_supervisor_id                        NUMBER (10);
   g_emp_object_version_number            NUMBER (20);
   g_emp_date_start                       DATE;
   g_actual_termination_date              DATE;
   g_final_process_date                   DATE;
   g_last_standard_process_date           DATE;
   g_asg_effective_start_date             DATE;
   g_asg_effective_end_date               DATE;
   g_ass_object_version_number            NUMBER;
   g_ass_obj_ver_number_emp               NUMBER;
   g_ass_obj_ver_number_cwk               NUMBER;
   g_actual_termination_date_emp          DATE;
   g_actual_termination_date_cwk          DATE;
   g_supervisor_assignment_id             NUMBER;
   g_error_msg                            VARCHAR2 (2000);
   g_rec_invalid                          NUMBER;
   g_rec_valid                            NUMBER;
   g_transaction_request_id               NUMBER
                                           := apps.fnd_global.conc_request_id;
   g_created_by                           VARCHAR2 (100)
                                                 := apps.fnd_global.user_name;

-------------------------------------------------------------------------
--VALIDATION FUNCTIONS
--------------------------------------------------------------------------
--------------------------------------------------------------------------
--
-- Function:  GET_BUSINESS_GROUP_ID
-- Description: Returns the business_group_id for specified
--              business_group.
--
-- Parameters:
-- p_business_group         in  VARCHAR2    business_group
-- p_latest_start_date      in  DATE        latest_start_date
--
-- Return:
--    Business_group_id.
--
-- Comments:
--   nil.
--
---------------------------------------------------------------------------
   FUNCTION get_business_group_id (p_employee_number IN NUMBER)
      RETURN NUMBER
   IS
      l_business_group_id   per_business_groups.business_group_id%TYPE;
      l_status_err          VARCHAR2 (30);
   BEGIN
      -- Commented by Makarandsingh Sisodiya on 13th Sept 2011 as per new Functional Specification V_1.4
       /*SELECT business_group_id
         INTO l_business_group_id
         FROM hr_all_organization_units
        WHERE NAME = p_business_group
          AND p_effective_date BETWEEN NVL (date_from, p_effective_date)
                                   AND NVL (date_to, p_effective_date);*/
      SELECT hao.business_group_id
        INTO l_business_group_id
        FROM hr_all_organization_units hao, hr_organization_information hoi
       WHERE hao.business_group_id =
                                   fnd_profile.VALUE ('PER_BUSINESS_GROUP_ID')
         AND hao.organization_id = hoi.organization_id
         AND hoi.org_information1 = 'HR_BG';

      RETURN l_business_group_id;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         xxccms_logging_util.log_audit_msg
            (p_transaction_request_id      => g_transaction_request_id,
             p_component_type              => xxccms_logging_util.c_comp_type_conc,
             p_transaction_name            => 'MOD014 - DT020-24 Employee Synchronisation SMS to CCMS ',
             p_source_system               => xxccms_logging_util.c_message_type_sms,
             p_source_name                 => xxccms_logging_util.c_message_type_sms,
             p_target_system               => xxccms_logging_util.c_message_type_ebs,
             p_target_name                 => xxccms_logging_util.c_message_type_ccms,
             p_message_source_type         => xxccms_logging_util.c_message_type_plsql,
             p_process_name                => 'xxccms_employeesync_pkg.get_business_group_id',
             p_process_stage               => xxccms_logging_util.c_message_type_intermediate,
             p_log_type                    => xxccms_logging_util.c_message_type_error,
             p_record_ref_key              => 'Employee Number',
             p_record_ref_value            => p_employee_number,
             p_message_code                => '2',
             p_message_description         => 'Business Group is not defined as HR Businees group, please ask setup team to perform this setup',
             p_send_email                  => 'N',
             p_email_id                    => NULL,
             p_time_stamp                  => SYSDATE,
             p_user_name                   => g_created_by,
             p_status                      => l_status_err
            );
         RETURN gc_error_code_no_data_found;
      WHEN OTHERS
      THEN
         xxccms_logging_util.log_audit_msg
            (p_transaction_request_id      => g_transaction_request_id,
             p_component_type              => xxccms_logging_util.c_comp_type_conc,
             p_transaction_name            => 'MOD014 - DT020-24 Employee Synchronisation SMS to CCMS ',
             p_source_system               => xxccms_logging_util.c_message_type_sms,
             p_source_name                 => xxccms_logging_util.c_message_type_sms,
             p_target_system               => xxccms_logging_util.c_message_type_ebs,
             p_target_name                 => xxccms_logging_util.c_message_type_ccms,
             p_message_source_type         => xxccms_logging_util.c_message_type_plsql,
             p_process_name                => 'xxccms_employeesync_pkg.get_business_group_id',
             p_process_stage               => xxccms_logging_util.c_message_type_intermediate,
             p_log_type                    => xxccms_logging_util.c_message_type_error,
             p_record_ref_key              => 'Employee Number',
             p_record_ref_value            => p_employee_number,
             p_message_code                => '3',
             p_message_description         =>    'Error While Fetching Buisnees Group '
                                              || ' ,refer log for details '
                                              || SUBSTR (SQLERRM, 1, 300),
             p_send_email                  => 'N',
             p_email_id                    => NULL,
             p_time_stamp                  => SYSDATE,
             p_user_name                   => g_created_by,
             p_status                      => l_status_err
            );
         RETURN gc_error_code_others;
   END get_business_group_id;

--------------------------------------------------------------------------
--
-- Function: GET_ORG_ID
-- Description: Returns the business_group_id for specified
--              organisation name.
--
-- Parameters:
-- p_organisation          IN  VARCHAR2    organisation name
-- p_business_grp_id       IN  NUMBER     business_group_id
--
-- Return:
--    organization_id
--
-- Comments:
--   nil.
--
---------------------------------------------------------------------------  
   
   FUNCTION get_org_id (p_employee_number IN NUMBER)
      RETURN NUMBER
   IS
      l_org_id       hr_all_organization_units.organization_id%TYPE;
      l_status_err   VARCHAR2 (30);
   BEGIN
      -- Commented by Makarandsingh Sisodiya on 13th Sept 2011 as per new Functional Specification V_1.4
      /*SELECT organization_id
        INTO l_org_id
        FROM hr_all_organization_units haou
       WHERE haou.NAME = p_organisation
         AND business_group_id = p_business_grp_id;*/
      SELECT hao.organization_id
        INTO l_org_id
        FROM hr_all_organization_units hao, hr_organization_information hoi
       WHERE hao.organization_id = fnd_profile.VALUE ('ORG_ID')
         AND hao.organization_id = hoi.organization_id
         AND hoi.org_information1 = 'HR_ORG';

      RETURN l_org_id;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         xxccms_logging_util.log_audit_msg
            (p_transaction_request_id      => g_transaction_request_id,
             p_component_type              => xxccms_logging_util.c_comp_type_conc,
             p_transaction_name            => 'MOD014 - DT020-24 Employee Synchronisation SMS to CCMS ',
             p_source_system               => xxccms_logging_util.c_message_type_sms,
             p_source_name                 => xxccms_logging_util.c_message_type_sms,
             p_target_system               => xxccms_logging_util.c_message_type_ebs,
             p_target_name                 => xxccms_logging_util.c_message_type_ccms,
             p_message_source_type         => xxccms_logging_util.c_message_type_plsql,
             p_process_name                => 'xxccms_employeesync_pkg.get_org_id',
             p_process_stage               => xxccms_logging_util.c_message_type_intermediate,
             p_log_type                    => xxccms_logging_util.c_message_type_error,
             p_record_ref_key              => 'Employee Number',
             p_record_ref_value            => p_employee_number,
             p_message_code                => '14',
             p_message_description         => 'Operating Unit is not defined as HR Organization, please ask setup team to perform this setup',
             p_send_email                  => 'N',
             p_email_id                    => NULL,
             p_time_stamp                  => SYSDATE,
             p_user_name                   => g_created_by,
             p_status                      => l_status_err
            );
         RETURN gc_error_code_no_data_found;
      WHEN OTHERS
      THEN
         xxccms_logging_util.log_audit_msg
            (p_transaction_request_id      => g_transaction_request_id,
             p_component_type              => xxccms_logging_util.c_comp_type_conc,
             p_transaction_name            => 'MOD014 - DT020-24 Employee Synchronisation SMS to CCMS ',
             p_source_system               => xxccms_logging_util.c_message_type_sms,
             p_source_name                 => xxccms_logging_util.c_message_type_sms,
             p_target_system               => xxccms_logging_util.c_message_type_ebs,
             p_target_name                 => xxccms_logging_util.c_message_type_ccms,
             p_message_source_type         => xxccms_logging_util.c_message_type_plsql,
             p_process_name                => 'xxccms_employeesync_pkg.get_org_id',
             p_process_stage               => xxccms_logging_util.c_message_type_intermediate,
             p_log_type                    => xxccms_logging_util.c_message_type_error,
             p_record_ref_key              => 'Employee Number',
             p_record_ref_value            => p_employee_number,
             p_message_code                => '15',
             p_message_description         =>    'Error occured while fetching Organisation'
                                              || ' ,refer log for details '
                                              || SUBSTR (SQLERRM, 1, 300),
             p_send_email                  => 'N',
             p_email_id                    => NULL,
             p_time_stamp                  => SYSDATE,
             p_user_name                   => g_created_by,
             p_status                      => l_status_err
            );
         RETURN gc_error_code_others;
   END get_org_id;

--------------------------------------------------------------------------
--
-- Procedure: VAL_EMP_NUM
-- Description: Used to get the person_id,object_version_number,
--              user_person_type, system_person_type and to set
--              the emp_flag and new_emp_cwk_flg.
--
-- Parameters:

   -- p_business_grp_id         IN     NUMBER      business_group_id
-- p_emp_num                    IN     VARCHAR2    employee number.
-- p_effective_date             IN     DATE        effective date
-- p_person_type_action         IN     VARCHAR2    Employee Type
-- x_person_id                  OUT NUMBER      person id
-- x_obj_ver_num                OUT NUMBER      object version number
-- x_sys_per_type               OUT VARCHAR2    system person type
-- x_user_per_type              OUT VARCHAR2    user person type
-- x_error_code                 OUT NUMBER      error code variable
-- x_emp_flag                   OUT VARCHAR2    employee flag
-- x_new_emp_cwk_flag           OUT VARCHAR2    new employee or cwk flag
-- Return:
--
-- Comments:
--   nil.  x_new_emp_cwk_flag
--
---------------------------------------------------------------------------
   PROCEDURE val_emp_num (
      p_business_grp_id      IN       NUMBER,
      p_emp_num              IN       VARCHAR2,
      p_effective_date       IN       DATE,
      p_person_type_action   IN       VARCHAR2,
      x_person_id            OUT      NUMBER,
      x_obj_ver_num          OUT      NUMBER,
      x_sys_per_type         OUT      VARCHAR2,
      x_user_per_type        OUT      VARCHAR2,
      x_last_update_date     OUT      DATE,
      x_emp_flag             OUT      VARCHAR2,
      x_new_emp_cwk_flag     OUT      VARCHAR2,
      x_error_code           OUT      NUMBER
   )
   IS
      l_status_err   VARCHAR2 (30);
   BEGIN
      SELECT pap.person_id, pap.object_version_number,
             ppt.system_person_type, ppt.user_person_type,
             pap.last_update_date
        INTO x_person_id, x_obj_ver_num,
             x_sys_per_type, x_user_per_type,
             x_last_update_date
        FROM per_all_people_f pap,
             per_person_type_usages_f ptu,
             per_person_types ppt
       WHERE pap.business_group_id = p_business_grp_id
         AND pap.employee_number = p_emp_num
         AND ptu.person_id = pap.person_id
         AND ptu.person_type_id = ppt.person_type_id
--         AND UPPER (ppt.user_person_type) = UPPER (p_person_type_action) -- Updated By Makarandsingh Sisodiya on 22-Sep-2011 as per artifact number artf1586535
         AND TRUNC (SYSDATE) BETWEEN pap.effective_start_date
                                 AND pap.effective_end_date
         AND TRUNC (SYSDATE) BETWEEN ptu.effective_start_date
                                 AND ptu.effective_end_date;

      x_new_emp_cwk_flag := 'N';
      x_emp_flag := 'Y';
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         xxccms_logging_util.log_audit_msg
            (p_transaction_request_id      => g_transaction_request_id,
             p_component_type              => xxccms_logging_util.c_comp_type_conc,
             p_transaction_name            => 'MOD014 - DT020-24 Employee Synchronisation SMS to CCMS ',
             p_source_system               => xxccms_logging_util.c_message_type_sms,
             p_source_name                 => xxccms_logging_util.c_message_type_sms,
             p_target_system               => xxccms_logging_util.c_message_type_ebs,
             p_target_name                 => xxccms_logging_util.c_message_type_ccms,
             p_message_source_type         => xxccms_logging_util.c_message_type_plsql,
             p_process_name                => 'xxccms_employeesync_pkg.val_emp_num',
             p_process_stage               => xxccms_logging_util.c_message_type_intermediate,
             p_log_type                    => xxccms_logging_util.c_message_type_info,
             p_record_ref_key              => 'Employee Number',
             p_record_ref_value            => p_emp_num,
             p_message_code                => '7',
             p_message_description         =>    'Person details not found for employee number '
                                              || p_emp_num,
             p_send_email                  => 'N',
             p_email_id                    => NULL,
             p_time_stamp                  => SYSDATE,
             p_user_name                   => g_created_by,
             p_status                      => l_status_err
            );
         x_new_emp_cwk_flag := 'Y';
         x_error_code := gc_error_code_no_data_found;
      WHEN OTHERS
      THEN
         xxccms_logging_util.log_audit_msg
            (p_transaction_request_id      => g_transaction_request_id,
             p_component_type              => xxccms_logging_util.c_comp_type_conc,
             p_transaction_name            => 'MOD014 - DT020-24 Employee Synchronisation SMS to CCMS ',
             p_source_system               => xxccms_logging_util.c_message_type_sms,
             p_source_name                 => xxccms_logging_util.c_message_type_sms,
             p_target_system               => xxccms_logging_util.c_message_type_ebs,
             p_target_name                 => xxccms_logging_util.c_message_type_ccms,
             p_message_source_type         => xxccms_logging_util.c_message_type_plsql,
             p_process_name                => 'xxccms_employeesync_pkg.val_emp_num',
             p_process_stage               => xxccms_logging_util.c_message_type_intermediate,
             p_log_type                    => xxccms_logging_util.c_message_type_error,
             p_record_ref_key              => 'Employee Number',
             p_record_ref_value            => p_emp_num,
             p_message_code                => '8',
             p_message_description         =>    'Unknown error occured while fetching person details, refer log for details'
                                              || SUBSTR (SQLERRM, 1, 200),
             p_send_email                  => 'N',
             p_email_id                    => NULL,
             p_time_stamp                  => SYSDATE,
             p_user_name                   => g_created_by,
             p_status                      => l_status_err
            );
         x_error_code := gc_error_code_others;
   END val_emp_num;

--------------------------------------------------------------------------
--------------------------------------------------------------------------
--
-- Function: GET_PERSON_TYPE_ID
-- Description: Returns the person_type_id for specified
--              person_type_action.
--
-- Parameters:
-- p_business_grp_id       IN  NUMBER      Business group id
-- p_person_id             IN  NUMBER      Person id
-- p_person_type_action    IN  VARCHAR2    Employee Type
--
-- Return:
--    person_type_id.
--
-- Comments:
--   nil. CWK_OBJECT_VERSION_BUMER
--
---------------------------------------------------------------------------
   FUNCTION get_person_type_id (
      p_business_grp_id      IN   NUMBER,
      p_person_type_action   IN   VARCHAR2,
      p_employee_number      IN   NUMBER
   )
      RETURN NUMBER
   IS
      l_person_type_id   per_person_types.person_type_id%TYPE;
      l_status_err       VARCHAR2 (30);
   BEGIN
      SELECT DISTINCT ppt.person_type_id
                 INTO l_person_type_id
                 FROM per_person_types ppt
                WHERE UPPER (ppt.user_person_type) =
                                                  UPPER (p_person_type_action)
                  AND ppt.business_group_id = p_business_grp_id
                  AND ppt.active_flag = 'Y';

      RETURN l_person_type_id;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         xxccms_logging_util.log_audit_msg
            (p_transaction_request_id      => g_transaction_request_id,
             p_component_type              => xxccms_logging_util.c_comp_type_conc,
             p_transaction_name            => 'MOD014 - DT020-24 Employee Synchronisation SMS to CCMS ',
             p_source_system               => xxccms_logging_util.c_message_type_sms,
             p_source_name                 => xxccms_logging_util.c_message_type_sms,
             p_target_system               => xxccms_logging_util.c_message_type_ebs,
             p_target_name                 => xxccms_logging_util.c_message_type_ccms,
             p_message_source_type         => xxccms_logging_util.c_message_type_plsql,
             p_process_name                => 'xxccms_employeesync_pkg.get_person_type_id',
             p_process_stage               => xxccms_logging_util.c_message_type_intermediate,
             p_log_type                    => xxccms_logging_util.c_message_type_error,
             p_record_ref_key              => 'Employee Number',
             p_record_ref_value            => p_employee_number,
             p_message_code                => '19',
             p_message_description         =>    'Person Type Id not found for person type action '
                                              || p_person_type_action,
             p_send_email                  => 'N',
             p_email_id                    => NULL,
             p_time_stamp                  => SYSDATE,
             p_user_name                   => g_created_by,
             p_status                      => l_status_err
            );
         RETURN gc_error_code_no_data_found;
      WHEN OTHERS
      THEN
         xxccms_logging_util.log_audit_msg
            (p_transaction_request_id      => g_transaction_request_id,
             p_component_type              => xxccms_logging_util.c_comp_type_conc,
             p_transaction_name            => 'MOD014 - DT020-24 Employee Synchronisation SMS to CCMS ',
             p_source_system               => xxccms_logging_util.c_message_type_sms,
             p_source_name                 => xxccms_logging_util.c_message_type_sms,
             p_target_system               => xxccms_logging_util.c_message_type_ebs,
             p_target_name                 => xxccms_logging_util.c_message_type_ccms,
             p_message_source_type         => xxccms_logging_util.c_message_type_plsql,
             p_process_name                => 'xxccms_employeesync_pkg.get_person_type_id',
             p_process_stage               => xxccms_logging_util.c_message_type_intermediate,
             p_log_type                    => xxccms_logging_util.c_message_type_error,
             p_record_ref_key              => 'Employee Number',
             p_record_ref_value            => p_employee_number,
             p_message_code                => '20',
             p_message_description         =>    'Unknown Error occured while fetching Person type id for Person type action'
                                              || p_person_type_action
                                              || ' ,refer log for details '
                                              || SUBSTR (SQLERRM, 1, 300),
             p_send_email                  => 'N',
             p_email_id                    => NULL,
             p_time_stamp                  => SYSDATE,
             p_user_name                   => g_created_by,
             p_status                      => l_status_err
            );
         RETURN gc_error_code_others;
   END get_person_type_id;

--------------------------------------------------------------------------
-- Created a new function to validate the code in datafile against
-- code in the system.
--
-- PROCEDURE:   val_lookup_code
-- Description: Returns the lookup code for specified lookup value.
--
-- Parameters:
-- p_lookup_type         IN     VARCHAR2    lookup_type
-- p_lookup_me           IN     VARCHAR2    lookup_meaning
-- p_effective_date      IN     DATE        effective_date
-- x_lookup_code         OUT    VARCHAR2    lookup_code
-- x_error_code          OUT    NUMBER      error code
--
-- Return:
--    Returns the lookup code and error code.
--
-- Comments:
--   nil.
----------------------------------------------------------------------------
   PROCEDURE val_lookup_code (
      p_lookup_type       IN       VARCHAR2,
      p_lookup_me         IN       VARCHAR2,
      p_effective_date    IN       DATE,
      p_employee_number   IN       NUMBER,
      x_lookup_code       OUT      VARCHAR2,
      x_error_code        OUT      NUMBER
   )
   AS
      l_status_err   VARCHAR2 (30);
   BEGIN
      SELECT lookup_code
        INTO x_lookup_code
        FROM hr_lookups
       WHERE lookup_type = p_lookup_type
         AND enabled_flag = 'Y'
         AND UPPER (lookup_code) =
                UPPER
                   (p_lookup_me)
-- Updated on 14th Sep 2011 By Makarandsingh Sisodiya as per artifact number artf1563386
         AND p_effective_date BETWEEN NVL (start_date_active,
                                           p_effective_date)
                                  AND NVL (end_date_active, p_effective_date);
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         xxccms_logging_util.log_audit_msg
            (p_transaction_request_id      => g_transaction_request_id,
             p_component_type              => xxccms_logging_util.c_comp_type_conc,
             p_transaction_name            => 'MOD014 - DT020-24 Employee Synchronisation SMS to CCMS ',
             p_source_system               => xxccms_logging_util.c_message_type_sms,
             p_source_name                 => xxccms_logging_util.c_message_type_sms,
             p_target_system               => xxccms_logging_util.c_message_type_ebs,
             p_target_name                 => xxccms_logging_util.c_message_type_ccms,
             p_message_source_type         => xxccms_logging_util.c_message_type_plsql,
             p_process_name                => 'xxccms_employeesync_pkg.val_lookup_code',
             p_process_stage               => xxccms_logging_util.c_message_type_intermediate,
             p_log_type                    => xxccms_logging_util.c_message_type_error,
             p_record_ref_key              => 'Employee Number',
             p_record_ref_value            => p_employee_number,
             p_message_code                => '24',
             p_message_description         =>    'Lookup Code not exist for '
                                              || p_lookup_type
                                              || ' lookup type',
             p_send_email                  => 'N',
             p_email_id                    => NULL,
             p_time_stamp                  => SYSDATE,
             p_user_name                   => g_created_by,
             p_status                      => l_status_err
            );
         x_lookup_code := gc_error_code_no_data_found;
      WHEN OTHERS
      THEN
         xxccms_logging_util.log_audit_msg
            (p_transaction_request_id      => g_transaction_request_id,
             p_component_type              => xxccms_logging_util.c_comp_type_conc,
             p_transaction_name            => 'MOD014 - DT020-24 Employee Synchronisation SMS to CCMS ',
             p_source_system               => xxccms_logging_util.c_message_type_sms,
             p_source_name                 => xxccms_logging_util.c_message_type_sms,
             p_target_system               => xxccms_logging_util.c_message_type_ebs,
             p_target_name                 => xxccms_logging_util.c_message_type_ccms,
             p_message_source_type         => xxccms_logging_util.c_message_type_plsql,
             p_process_name                => 'xxccms_employeesync_pkg.val_lookup_code',
             p_process_stage               => xxccms_logging_util.c_message_type_intermediate,
             p_log_type                    => xxccms_logging_util.c_message_type_error,
             p_record_ref_key              => 'Employee Number',
             p_record_ref_value            => p_employee_number,
             p_message_code                => '25',
             p_message_description         =>    'Unknown error occured while fetching lookup code for lookup type '
                                              || p_lookup_type
                                              || ' ,refer log for details '
                                              || SUBSTR (SQLERRM, 1, 300),
             p_send_email                  => 'N',
             p_email_id                    => NULL,
             p_time_stamp                  => SYSDATE,
             p_user_name                   => g_created_by,
             p_status                      => l_status_err
            );
         x_lookup_code := gc_error_code_others;
   END val_lookup_code;

--------------------------------------------------------------------------
--
-- Function: GET_JOB_ID
-- Description: Returns the job_id for specified
--              job.
--
-- Parameters:
-- p_job                   IN  VARCHAR    job
-- p_business_grp_id       IN  NUMBER     business_group_id
-- p_effective_date        IN  DATE       effective_start_date
--
-- Return:
--    job_id
--
-- Comments:
--   nil.
--
---------------------------------------------------------------------------
-- Commented by Makarandsingh Sisodiya on 12-Sept-2011 as per new Functional Specification
-- Verison V_1.4_Issued

   /****************************************************************************************

   FUNCTION get_job_id (
      p_job               IN   VARCHAR2,
      p_business_grp_id   IN   per_business_groups.business_group_id%TYPE,
      p_effective_date    IN   DATE,
      p_employee_number   IN   NUMBER
   )
      RETURN NUMBER
   IS
      l_job_id   per_jobs.job_id%TYPE;
      l_status_err   varchar2(30);
   BEGIN
      SELECT job_id
        INTO l_job_id
        FROM per_jobs
       WHERE UPPER (NAME) = UPPER (p_job)
         AND business_group_id = p_business_grp_id
         AND p_effective_date BETWEEN NVL (date_from, p_effective_date)
                                  AND NVL (date_to, p_effective_date);

      RETURN l_job_id;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
      xxccms_logging_util.log_audit_msg
            (p_transaction_request_id      => g_transaction_request_id,
             p_component_type              => xxccms_logging_util.c_comp_type_conc,
             p_transaction_name            => 'MOD014 - DT020-24 Employee Synchronisation SMS to CCMS ',
             p_source_system               => xxccms_logging_util.c_message_type_sms,
             p_source_name                 => xxccms_logging_util.c_message_type_sms,
             p_target_system               => xxccms_logging_util.c_message_type_ebs,
             p_target_name                 => xxccms_logging_util.c_message_type_ccms,
             p_message_source_type         => xxccms_logging_util.c_message_type_plsql,
             p_process_name                => 'xxccms_employeesync_pkg.get_job_id',
             p_process_stage               => xxccms_logging_util.c_message_type_intermediate,
             p_log_type                    => xxccms_logging_util.c_message_type_error,
             p_record_ref_key              => 'Employee Number',
             p_record_ref_value            => p_employee_number,
             p_message_code                => '31',
             p_message_description         => 'Job Id not found for Job Name '||p_job ,
             p_send_email                  => 'N',
             p_email_id                    => NULL,
             p_time_stamp                  => SYSDATE,
             p_user_name                   => g_created_by,
             p_status                      => l_status_err
            );
         RETURN gc_error_code_no_data_found;
      WHEN OTHERS
      THEN
      xxccms_logging_util.log_audit_msg
            (p_transaction_request_id      => g_transaction_request_id,
             p_component_type              => xxccms_logging_util.c_comp_type_conc,
             p_transaction_name            => 'MOD014 - DT020-24 Employee Synchronisation SMS to CCMS ',
             p_source_system               => xxccms_logging_util.c_message_type_sms,
             p_source_name                 => xxccms_logging_util.c_message_type_sms,
             p_target_system               => xxccms_logging_util.c_message_type_ebs,
             p_target_name                 => xxccms_logging_util.c_message_type_ccms,
             p_message_source_type         => xxccms_logging_util.c_message_type_plsql,
             p_process_name                => 'xxccms_employeesync_pkg.get_job_id',
             p_process_stage               => xxccms_logging_util.c_message_type_intermediate,
             p_log_type                    => xxccms_logging_util.c_message_type_error,
             p_record_ref_key              => 'Employee Number',
             p_record_ref_value            => p_employee_number,
             p_message_code                => '32',
             p_message_description         => 'Unknown Error occured while fetching Job Id for Job Name ' ||p_job
                       || ' ,refer log for details'|| SUBSTR(SQLERRM,1,200),
             p_send_email                  => 'N',
             p_email_id                    => NULL,
             p_time_stamp                  => SYSDATE,
             p_user_name                   => g_created_by,
             p_status                      => l_status_err
            );
         RETURN gc_error_code_others;
   END get_job_id;
*************************************************************************************************/
--------------------------------------------------------------------------
--
-- Function: GET_LOCATION_ID
-- Description: Returns the location_id for specified
--              location.
--
-- Parameters:
-- p_location              IN  VARCHAR2    location
-- p_business_grp_id       IN  NUMBER      business_group_id
--
-- Return:
--    location_id
--
-- Comments:
--   nil.
--
---------------------------------------------------------------------------
   FUNCTION get_location_id (
      p_location          IN   VARCHAR2,
      p_business_grp_id   IN   per_business_groups.business_group_id%TYPE,
      p_employee_number   IN   NUMBER
   )
      RETURN NUMBER
   IS
      l_location_id   hr_locations_all.location_id%TYPE;
      l_status_err    VARCHAR2 (30);
   BEGIN
      SELECT location_id
        INTO l_location_id
        FROM hr.hr_locations_all
       WHERE location_code = p_location;

      RETURN l_location_id;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         xxccms_logging_util.log_audit_msg
            (p_transaction_request_id      => g_transaction_request_id,
             p_component_type              => xxccms_logging_util.c_comp_type_conc,
             p_transaction_name            => 'MOD014 - DT020-24 Employee Synchronisation SMS to CCMS ',
             p_source_system               => xxccms_logging_util.c_message_type_sms,
             p_source_name                 => xxccms_logging_util.c_message_type_sms,
             p_target_system               => xxccms_logging_util.c_message_type_ebs,
             p_target_name                 => xxccms_logging_util.c_message_type_ccms,
             p_message_source_type         => xxccms_logging_util.c_message_type_plsql,
             p_process_name                => 'xxccms_employeesync_pkg.get_location_id',
             p_process_stage               => xxccms_logging_util.c_message_type_intermediate,
             p_log_type                    => xxccms_logging_util.c_message_type_error,
             p_record_ref_key              => 'Employee Number',
             p_record_ref_value            => p_employee_number,
             p_message_code                => '34',
             p_message_description         =>    'Location id Does not exist for location name '
                                              || p_location,
             p_send_email                  => 'N',
             p_email_id                    => NULL,
             p_time_stamp                  => SYSDATE,
             p_user_name                   => g_created_by,
             p_status                      => l_status_err
            );
         RETURN gc_error_code_no_data_found;
      WHEN OTHERS
      THEN
         xxccms_logging_util.log_audit_msg
            (p_transaction_request_id      => g_transaction_request_id,
             p_component_type              => xxccms_logging_util.c_comp_type_conc,
             p_transaction_name            => 'MOD014 - DT020-24 Employee Synchronisation SMS to CCMS ',
             p_source_system               => xxccms_logging_util.c_message_type_sms,
             p_source_name                 => xxccms_logging_util.c_message_type_sms,
             p_target_system               => xxccms_logging_util.c_message_type_ebs,
             p_target_name                 => xxccms_logging_util.c_message_type_ccms,
             p_message_source_type         => xxccms_logging_util.c_message_type_plsql,
             p_process_name                => 'xxccms_employeesync_pkg.get_location_id',
             p_process_stage               => xxccms_logging_util.c_message_type_intermediate,
             p_log_type                    => xxccms_logging_util.c_message_type_error,
             p_record_ref_key              => 'Employee Number',
             p_record_ref_value            => p_employee_number,
             p_message_code                => '35',
             p_message_description         =>    'Unknown exception occured while fetching the location id for location name '
                                              || p_location
                                              || ' ,refer error log for details'
                                              || SUBSTR (SQLERRM, 1, 300),
             p_send_email                  => 'N',
             p_email_id                    => NULL,
             p_time_stamp                  => SYSDATE,
             p_user_name                   => g_created_by,
             p_status                      => l_status_err
            );
         RETURN gc_error_code_others;
   END get_location_id;

--------------------------------------------------------------------------
--
-- Function: GET_SUPERVISOR_ID
-- Description: checks the valid supervisor
--
-- Parameters:
-- p_emp_num            IN  VARCHAR 2   employee_number
-- p_business_grp_id    IN  VARCHAR2    business_group_id
-- p_eff_start_dt       IN  DATE        effective_start_date
--
-- Return:
--    person_id.
--
-- Comments:
--   nil.
--
---------------------------------------------------------------------------
   FUNCTION get_supervisor_id (
      p_supervisor_num    IN   VARCHAR2,
      p_emp_num           IN   VARCHAR2,
      p_effective_date    IN   DATE,
      p_business_grp_id   IN   VARCHAR2
   )
      RETURN NUMBER
   IS
      l_sup_id       per_all_people_f.person_id%TYPE;
      l_status_err   VARCHAR2 (30);
   BEGIN
      SELECT pap.person_id
        INTO l_sup_id
        FROM per_all_people_f pap                     --, per_person_types ppt
       WHERE pap.business_group_id = p_business_grp_id
         AND pap.employee_number = p_supervisor_num
         AND p_effective_date BETWEEN pap.effective_start_date
                                  AND pap.effective_end_date;

      RETURN l_sup_id;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         xxccms_logging_util.log_audit_msg
            (p_transaction_request_id      => g_transaction_request_id,
             p_component_type              => xxccms_logging_util.c_comp_type_conc,
             p_transaction_name            => 'MOD014 - DT020-24 Employee Synchronisation SMS to CCMS ',
             p_source_system               => xxccms_logging_util.c_message_type_sms,
             p_source_name                 => xxccms_logging_util.c_message_type_sms,
             p_target_system               => xxccms_logging_util.c_message_type_ebs,
             p_target_name                 => xxccms_logging_util.c_message_type_ccms,
             p_message_source_type         => xxccms_logging_util.c_message_type_plsql,
             p_process_name                => 'xxccms_employeesync_pkg.get_supervisor_id',
             p_process_stage               => xxccms_logging_util.c_message_type_intermediate,
             p_log_type                    => xxccms_logging_util.c_message_type_warning,
             p_record_ref_key              => 'Employee Number',
             p_record_ref_value            => p_emp_num,
             p_message_code                => '37',
             p_message_description         =>    'Supervisor Number '
                                              || p_supervisor_num
                                              || ' does not Exist as Employee',
             p_send_email                  => 'N',
             p_email_id                    => NULL,
             p_time_stamp                  => SYSDATE,
             p_user_name                   => g_created_by,
             p_status                      => l_status_err
            );
         RETURN gc_error_code_no_data_found;
      WHEN OTHERS
      THEN
         xxccms_logging_util.log_audit_msg
            (p_transaction_request_id      => g_transaction_request_id,
             p_component_type              => xxccms_logging_util.c_comp_type_conc,
             p_transaction_name            => 'MOD014 - DT020-24 Employee Synchronisation SMS to CCMS ',
             p_source_system               => xxccms_logging_util.c_message_type_sms,
             p_source_name                 => xxccms_logging_util.c_message_type_sms,
             p_target_system               => xxccms_logging_util.c_message_type_ebs,
             p_target_name                 => xxccms_logging_util.c_message_type_ccms,
             p_message_source_type         => xxccms_logging_util.c_message_type_plsql,
             p_process_name                => 'xxccms_employeesync_pkg.get_supervisor_id',
             p_process_stage               => xxccms_logging_util.c_message_type_intermediate,
             p_log_type                    => xxccms_logging_util.c_message_type_error,
             p_record_ref_key              => 'Employee Number',
             p_record_ref_value            => p_emp_num,
             p_message_code                => '38',
             p_message_description         =>    'Unknown Error occured while fetching detail for Supervisor id '
                                              || p_supervisor_num
                                              || ' and Businedd group id as '
                                              || p_business_grp_id
                                              || ' ,refer log for details '
                                              || SUBSTR (SQLERRM, 1, 300),
             p_send_email                  => 'N',
             p_email_id                    => NULL,
             p_time_stamp                  => SYSDATE,
             p_user_name                   => g_created_by,
             p_status                      => l_status_err
            );
         RETURN gc_error_code_others;
   END get_supervisor_id;

-------------------------------------------------------------------------
--
-- Procedure: GET_ASSIGNMENT_ID
-- Description: Returns the assignment_id, assignment_number
--              object_version_number for specified
--              person_id.
--
-- Parameters:
-- p_person_id              IN     VARCHAR2   person_id
-- p_business_grp_id        IN     VARCHAR2   business_group_id
-- p_effective_date         IN     DATE       effective_start_date
-- x_assignment_num            OUT VARCHAR2   assignment_number
-- x_assignment_id             OUT NUMBER     assignment_id
-- x_obj_ver_num               OUT NUMBER     object_version_number
-- x_assign_error              OUT NUMBER    error code
-- x_ass_eff_st_dt             OUT per_all_assignments_f.effective_start_date%TYPE
-- Return:
--
-- Comments:
--   nil.
--
---------------------------------------------------------------------------
   PROCEDURE get_assignment_id (
      p_person_id         IN       per_all_assignments_f.person_id%TYPE,
      p_business_grp_id   IN       VARCHAR2,
      p_effective_date    IN       DATE,
      p_employee_number   IN       NUMBER,
      x_assignment_num    OUT      per_all_assignments_f.assignment_number%TYPE,
      x_assignment_id     OUT      per_all_assignments_f.assignment_id%TYPE,
      x_obj_ver_num       OUT      per_all_assignments_f.object_version_number%TYPE,
      x_assign_error      OUT      NUMBER,
      x_ass_eff_st_dt     OUT      per_all_assignments_f.effective_start_date%TYPE
   )
   IS
      l_status_err   VARCHAR2 (30);
   BEGIN
      SELECT assignment_id, assignment_number, object_version_number,
             effective_start_date
        INTO x_assignment_id, x_assignment_num, x_obj_ver_num,
             x_ass_eff_st_dt
        FROM per_all_assignments_f
       WHERE person_id = p_person_id
         AND business_group_id = p_business_grp_id
         AND primary_flag = 'Y'
         AND p_effective_date BETWEEN effective_start_date
                                  AND NVL (effective_end_date,
                                           p_effective_date
                                          );
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         xxccms_logging_util.log_audit_msg
            (p_transaction_request_id      => g_transaction_request_id,
             p_component_type              => xxccms_logging_util.c_comp_type_conc,
             p_transaction_name            => 'MOD014 - DT020-24 Employee Synchronisation SMS to CCMS ',
             p_source_system               => xxccms_logging_util.c_message_type_sms,
             p_source_name                 => xxccms_logging_util.c_message_type_sms,
             p_target_system               => xxccms_logging_util.c_message_type_ebs,
             p_target_name                 => xxccms_logging_util.c_message_type_ccms,
             p_message_source_type         => xxccms_logging_util.c_message_type_plsql,
             p_process_name                => 'xxccms_employeesync_pkg.get_assignment_id',
             p_process_stage               => xxccms_logging_util.c_message_type_intermediate,
             p_log_type                    => xxccms_logging_util.c_message_type_error,
             p_record_ref_key              => 'Employee Number',
             p_record_ref_value            => p_employee_number,
             p_message_code                => '42',
             p_message_description         => 'Assigment not found for this employee',
             p_send_email                  => 'N',
             p_email_id                    => NULL,
             p_time_stamp                  => SYSDATE,
             p_user_name                   => g_created_by,
             p_status                      => l_status_err
            );
         x_assign_error := gc_error_code_no_data_found;
      WHEN OTHERS
      THEN
         xxccms_logging_util.log_audit_msg
            (p_transaction_request_id      => g_transaction_request_id,
             p_component_type              => xxccms_logging_util.c_comp_type_conc,
             p_transaction_name            => 'MOD014 - DT020-24 Employee Synchronisation SMS to CCMS ',
             p_source_system               => xxccms_logging_util.c_message_type_sms,
             p_source_name                 => xxccms_logging_util.c_message_type_sms,
             p_target_system               => xxccms_logging_util.c_message_type_ebs,
             p_target_name                 => xxccms_logging_util.c_message_type_ccms,
             p_message_source_type         => xxccms_logging_util.c_message_type_plsql,
             p_process_name                => 'xxccms_employeesync_pkg.get_assignment_id',
             p_process_stage               => xxccms_logging_util.c_message_type_intermediate,
             p_log_type                    => xxccms_logging_util.c_message_type_error,
             p_record_ref_key              => 'Employee Number',
             p_record_ref_value            => p_employee_number,
             p_message_code                => '43',
             p_message_description         => 'Unknown Error occured while fetching Assignment id',
             p_send_email                  => 'N',
             p_email_id                    => NULL,
             p_time_stamp                  => SYSDATE,
             p_user_name                   => g_created_by,
             p_status                      => l_status_err
            );
         x_assign_error := gc_error_code_others;
   END get_assignment_id;

-------------------------------------------------------------------------
--
-- Procedure: GET_SUPER_ASSIGNMENT_ID
-- Description: Returns the supervisor_assignment_id
--
-- Parameters:
-- p_person_id              IN    VARCHAR2   person_id
-- p_business_grp_id        IN    VARCHAR2   business_group_id
-- p_effective_date         IN    DATE       effective_start_date
-- p_employee_number     IN    NUMBER     employee number ,
-- x_super_assignment_id      OUT NUMBER     assignment_id
-- x_assign_error             OUT NUMBER     error code
--
-- Return:
--
-- Comments:
--   nil.
--
---------------------------------------------------------------------------
   PROCEDURE get_super_assignment_id (
      p_supervisor_id         IN       per_all_assignments_f.person_id%TYPE,
      p_business_grp_id       IN       VARCHAR2,
      p_effective_date        IN       DATE,
      p_employee_number       IN       NUMBER,
      x_super_assignment_id   OUT      per_all_assignments_f.assignment_id%TYPE,
      x_assign_error          OUT      NUMBER
   )
   IS
      l_status_err   VARCHAR2 (30);
   BEGIN
      SELECT assignment_id
        INTO x_super_assignment_id
        FROM per_all_assignments_f
       WHERE person_id = p_supervisor_id
         AND business_group_id = p_business_grp_id
         AND primary_flag = 'Y'
         AND p_effective_date BETWEEN effective_start_date
                                  AND NVL (effective_end_date,
                                           p_effective_date
                                          );
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         xxccms_logging_util.log_audit_msg
            (p_transaction_request_id      => g_transaction_request_id,
             p_component_type              => xxccms_logging_util.c_comp_type_conc,
             p_transaction_name            => 'MOD014 - DT020-24 Employee Synchronisation SMS to CCMS ',
             p_source_system               => xxccms_logging_util.c_message_type_sms,
             p_source_name                 => xxccms_logging_util.c_message_type_sms,
             p_target_system               => xxccms_logging_util.c_message_type_ebs,
             p_target_name                 => xxccms_logging_util.c_message_type_ccms,
             p_message_source_type         => xxccms_logging_util.c_message_type_plsql,
             p_process_name                => 'xxccms_employeesync_pkg.get_super_assignment_id',
             p_process_stage               => xxccms_logging_util.c_message_type_intermediate,
             p_log_type                    => xxccms_logging_util.c_message_type_error,
             p_record_ref_key              => 'Employee Number',
             p_record_ref_value            => p_employee_number,
             p_message_code                => '47',
             p_message_description         => 'No data found while retriving Supervisor Assignment id ',
             p_send_email                  => 'N',
             p_email_id                    => NULL,
             p_time_stamp                  => SYSDATE,
             p_user_name                   => g_created_by,
             p_status                      => l_status_err
            );
         x_assign_error := gc_error_code_no_data_found;
      WHEN OTHERS
      THEN
         xxccms_logging_util.log_audit_msg
            (p_transaction_request_id      => g_transaction_request_id,
             p_component_type              => xxccms_logging_util.c_comp_type_conc,
             p_transaction_name            => 'MOD014 - DT020-24 Employee Synchronisation SMS to CCMS ',
             p_source_system               => xxccms_logging_util.c_message_type_sms,
             p_source_name                 => xxccms_logging_util.c_message_type_sms,
             p_target_system               => xxccms_logging_util.c_message_type_ebs,
             p_target_name                 => xxccms_logging_util.c_message_type_ccms,
             p_message_source_type         => xxccms_logging_util.c_message_type_plsql,
             p_process_name                => 'xxccms_employeesync_pkg.get_super_assignment_id',
             p_process_stage               => xxccms_logging_util.c_message_type_intermediate,
             p_log_type                    => xxccms_logging_util.c_message_type_error,
             p_record_ref_key              => 'Employee Number',
             p_record_ref_value            => p_employee_number,
             p_message_code                => '48',
             p_message_description         =>    'Unknown exception occured while fetching supervisor assignment id, refer error log for detail - '
                                              || SUBSTR (SQLERRM, 1, 300),
             p_send_email                  => 'N',
             p_email_id                    => NULL,
             p_time_stamp                  => SYSDATE,
             p_user_name                   => g_created_by,
             p_status                      => l_status_err
            );
         x_assign_error := gc_error_code_others;
   END get_super_assignment_id;

   --------------------------------------------------------------------------
--
-- Procedure: GET_EMP_OBJECT_VERSION_NUMBER
-- Description: Returns the
--              object_version_number for specified
--              person_id.
--
-- Parameters:
-- p_person_id                  IN     VARCHAR2   person_id
-- x_emp_date_start                OUT DATE       date_start.
-- x_per_service_id                OUT NUMBER     period of service id
-- x_emp_object_version_number     OUT VARCHAR2   object version number.
-- x_assign_error                  OUT NUMBER     error number.
--
-- Comments:
--    nil.
--
-------------------------------------------------------------------------------
   PROCEDURE get_emp_object_version_number (
      p_person_id                     IN       NUMBER,
      p_employee_number               IN       NUMBER,
      x_emp_date_start                OUT      DATE,
      x_per_service_id                OUT      NUMBER,
      x_emp_object_version_number     OUT      NUMBER,
      x_actual_termination_date_emp   OUT      DATE,
      x_assign_error                  OUT      NUMBER
   )
   IS
      l_status_err   VARCHAR2 (30);
   BEGIN
      SELECT pps.object_version_number, pps.date_start,
             pps.period_of_service_id, pps.actual_termination_date
        INTO x_emp_object_version_number, x_emp_date_start,
             x_per_service_id, x_actual_termination_date_emp
        FROM per_periods_of_service pps
       WHERE person_id = p_person_id
         AND period_of_service_id = (SELECT MAX (period_of_service_id)
                                       FROM per_periods_of_service pps1
                                      WHERE pps1.person_id = p_person_id);
--        FROM per_periods_of_service pps
--       WHERE person_id = p_person_id;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         xxccms_logging_util.log_audit_msg
            (p_transaction_request_id      => g_transaction_request_id,
             p_component_type              => xxccms_logging_util.c_comp_type_conc,
             p_transaction_name            => 'MOD014 - DT020-24 Employee Synchronisation SMS to CCMS ',
             p_source_system               => xxccms_logging_util.c_message_type_sms,
             p_source_name                 => xxccms_logging_util.c_message_type_sms,
             p_target_system               => xxccms_logging_util.c_message_type_ebs,
             p_target_name                 => xxccms_logging_util.c_message_type_ccms,
             p_message_source_type         => xxccms_logging_util.c_message_type_plsql,
             p_process_name                => 'xxccms_employeesync_pkg.get_emp_object_version_number',
             p_process_stage               => xxccms_logging_util.c_message_type_intermediate,
             p_log_type                    => xxccms_logging_util.c_message_type_error,
             p_record_ref_key              => 'Employee Number',
             p_record_ref_value            => p_employee_number,
             p_message_code                => '53',
             p_message_description         =>    'Object Version Number not found for person id '
                                              || p_person_id,
             p_send_email                  => 'N',
             p_email_id                    => NULL,
             p_time_stamp                  => SYSDATE,
             p_user_name                   => g_created_by,
             p_status                      => l_status_err
            );
         x_assign_error := gc_error_code_no_data_found;
      WHEN OTHERS
      THEN
         xxccms_logging_util.log_audit_msg
            (p_transaction_request_id      => g_transaction_request_id,
             p_component_type              => xxccms_logging_util.c_comp_type_conc,
             p_transaction_name            => 'MOD014 - DT020-24 Employee Synchronisation SMS to CCMS ',
             p_source_system               => xxccms_logging_util.c_message_type_sms,
             p_source_name                 => xxccms_logging_util.c_message_type_sms,
             p_target_system               => xxccms_logging_util.c_message_type_ebs,
             p_target_name                 => xxccms_logging_util.c_message_type_ccms,
             p_message_source_type         => xxccms_logging_util.c_message_type_plsql,
             p_process_name                => 'xxccms_employeesync_pkg.get_emp_object_version_number',
             p_process_stage               => xxccms_logging_util.c_message_type_intermediate,
             p_log_type                    => xxccms_logging_util.c_message_type_error,
             p_record_ref_key              => 'Employee Number',
             p_record_ref_value            => p_employee_number,
             p_message_code                => '54',
             p_message_description         =>    'Unknown Error occured while fetching Object Version number for person '
                                              || p_person_id
                                              || ', refer error log for detail- '
                                              || SUBSTR (SQLERRM, 1, 300),
             p_send_email                  => 'N',
             p_email_id                    => NULL,
             p_time_stamp                  => SYSDATE,
             p_user_name                   => g_created_by,
             p_status                      => l_status_err
            );
         x_assign_error := gc_error_code_others;
   END get_emp_object_version_number;

--------------------------------------------------------------
-- PROCEDURE   : CREATE_EMPLOYEE
-- Description : This procedure calls the HRMS public API
--               hr_employee_api.create_gb_employee to create
--               employee with in a GB legislation
--------------------------------------------------------------
   PROCEDURE create_employee
   IS
      x_person_id                   NUMBER (10);
      x_assignment_id               NUMBER (10);
      x_per_object_version_number   NUMBER (10);
      x_asg_object_version_number   NUMBER (10);
      x_per_effective_start_date    DATE;
      x_per_effective_end_date      DATE;
      x_full_name                   VARCHAR2 (200);
      x_per_comment_id              NUMBER (10);
      x_assignment_sequence         NUMBER (10);
      x_assignment_number           VARCHAR2 (20);
      x_name_combination_warning    BOOLEAN;
      x_assign_payroll_warning      BOOLEAN;
      x_orig_hire_warning           BOOLEAN;
      l_null                        VARCHAR2 (200);
      l_status                      VARCHAR2 (20);
   BEGIN
      -- g_employee_number            := NULL;
      g_person_id := NULL;
      g_assignment_id := NULL;
      g_per_object_version_number := NULL;
      g_asg_object_version_number := NULL;
      g_per_effective_start_date := NULL;
      g_per_effective_end_date := NULL;
      x_full_name := NULL;
      x_per_comment_id := NULL;
      x_assignment_sequence := NULL;
      g_assignment_number := NULL;
      x_name_combination_warning := NULL;
      x_assign_payroll_warning := NULL;
      x_orig_hire_warning := NULL;
      l_null := NULL;
      hr_employee_api.create_gb_employee
                 (p_validate                       => FALSE,
                  p_hire_date                      => g_latest_start_date,
                  p_business_group_id              => g_business_group_id,
                  p_last_name                      => g_last_name,
                  p_sex                            => g_gender,
                  p_person_type_id                 => g_person_type_id,
                  p_date_of_birth                  => g_dob,
                  p_employee_number                => g_employee_number,
                  p_first_name                     => g_first_name,
                  p_title                          => g_title,
                  p_person_id                      => g_person_id,
                  p_assignment_id                  => g_assignment_id,
                  p_per_object_version_number      => g_per_object_version_number,
                  p_asg_object_version_number      => g_ass_obj_ver_number_emp,
                  p_per_effective_start_date       => g_per_effective_start_date,
                  p_per_effective_end_date         => g_per_effective_end_date,
                  p_full_name                      => x_full_name,
                  p_per_comment_id                 => x_per_comment_id,
                  p_assignment_sequence            => x_assignment_sequence,
                  p_assignment_number              => g_assignment_number,
                  p_name_combination_warning       => x_name_combination_warning,
                  p_assign_payroll_warning         => x_assign_payroll_warning,
                  p_orig_hire_warning              => x_orig_hire_warning
                 );
      g_success := 'Y';
      -- Added Commit By Makarandsingh Sisodiya on 22-Sep-2011 as per artifact number artf1586535
      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         g_success := 'N';
         g_error_column_value :=
                         g_error_column_value || ',' || '-CREATE_GB_EMPLOYEE';
         g_error_msg := g_error_msg || ', ' || SUBSTR (SQLERRM, 1, 300);
         xxccms_logging_util.log_audit_msg
            (p_transaction_request_id      => g_transaction_request_id,
             p_component_type              => xxccms_logging_util.c_comp_type_conc,
             p_transaction_name            => 'MOD014 - DT020-24 Employee Synchronisation SMS to CCMS ',
             p_source_system               => xxccms_logging_util.c_message_type_sms,
             p_source_name                 => xxccms_logging_util.c_message_type_sms,
             p_target_system               => xxccms_logging_util.c_message_type_ebs,
             p_target_name                 => xxccms_logging_util.c_message_type_ccms,
             p_message_source_type         => xxccms_logging_util.c_message_type_plsql,
             p_process_name                => 'xxccms_employeesync_pkg.create_employee',
             p_process_stage               => xxccms_logging_util.c_message_type_intermediate,
             p_log_type                    => xxccms_logging_util.c_message_type_error,
             p_record_ref_key              => 'Employee Number',
             p_record_ref_value            => g_employee_number,
             p_message_code                => '59',
             p_message_description         =>    'Unknown Error Occured while Creating Employee with person id '
                                              || x_person_id
                                              || ' ,refer log for details '
                                              || SUBSTR (SQLERRM, 1, 300),
             p_send_email                  => 'N',
             p_email_id                    => NULL,
             p_time_stamp                  => SYSDATE,
             p_user_name                   => g_created_by,
             p_status                      => l_status
            );
   END create_employee;

/* --------------------------------------------------------------
-- PROCEDURE   : CREATE_CONTINGENT_WORKER
-- Description : This procedure calls the HRMS public API
--               hr_contingent_worker_api.create_cwk to create
--               contingent worker with in a GB legislation
--------------------------------------------------------------
   PROCEDURE create_contingent_worker
   IS
   BEGIN
      g_ass_obj_ver_number_cwk          :=null;
      -- g_employee_number               :=null;
      g_person_id                       :=null;
      g_per_object_version_number       :=null;
      g_per_effective_start_date        :=null;
      g_per_effective_end_date          :=null;
      g_pdp_object_version_number       :=null;
      g_full_name                       :=null;
      g_comment_id                      :=null;
      g_assignment_id                   :=null;
      g_asg_object_version_number       :=null;
      g_assignment_sequence             :=null;
      g_assignment_number               :=null;
      g_name_combination_warning        :=null;

      hr_contingent_worker_api.create_cwk
         (p_validate                      => false
         ,p_start_date                    => g_latest_start_date
         ,p_business_group_id             => g_business_group_id
         ,p_last_name                     => g_last_name
         ,p_person_type_id                => g_person_type_id
         ,p_npw_number                    => g_employee_number
         ,p_date_of_birth                 => g_dob
         ,p_first_name                    => g_first_name
         ,p_sex                           => g_gender
         ,p_title                         => g_title
         ,p_person_id                     => g_person_id
         ,p_per_object_version_number     => g_per_object_version_number
         ,p_per_effective_start_date      => g_per_effective_start_date
         ,p_per_effective_end_date        => g_per_effective_end_date
         ,p_pdp_object_version_number     => g_pdp_object_version_number
         ,p_full_name                     => g_full_name
         ,p_comment_id                    => g_comment_id
         ,p_assignment_id                 => g_assignment_id
         ,p_asg_object_version_number     => g_ass_obj_ver_number_cwk
         ,p_assignment_sequence           => g_assignment_sequence
         ,p_assignment_number             => g_assignment_number
         ,p_name_combination_warning      => g_name_combination_warning
         );


      g_success:='Y';
   EXCEPTION
      WHEN OTHERS
      THEN
         g_success:='N';
         g_error_column_value := g_error_column_value||','||'-CREATE_CWK';
         g_error_msg          := g_error_msg||', '||SUBSTR (SQLERRM,1,300);
         g_linecount :=g_linecount+1;
         xxccms_logging_util.log_audit_msg
         (p_transaction_request_id      => g_transaction_request_id,
          p_component_type              => xxccms_logging_util.c_comp_type_conc,
          p_transaction_name            => 'MOD014 - DT020-24 Employee Synchronisation SMS to CCMS',
          p_source_system               => xxccms_logging_util.c_message_type_sms,
          p_source_name                 => xxccms_logging_util.c_message_type_sms,
          p_target_system               => xxccms_logging_util.c_message_type_ebs,
          p_target_name                 => xxccms_logging_util.c_message_type_ccms,
          p_message_source_type         => xxccms_logging_util.c_message_type_plsql,
          p_process_name                => 'xxccms_employeesync_pkg.create_contingent_worker',
          p_process_stage               => xxccms_logging_util. c_message_type_intermediate,
          p_log_type                    => xxccms_logging_util.c_message_type_error,
          p_record_ref_key              => 'Employee Number',
          p_record_ref_value            => g_employee_number,
          p_message_code                => '',
          p_message_description         => 'Unknown Error Occured while Creating Contingent worker, refer error log for details',
          p_send_email                  => 'N',
          p_email_id                    => NULL,
          p_time_stamp                  => SYSDATE,
           p_user_name                  => g_created_by,
          p_status                      => l_status
         );
   END create_contingent_worker; */
--------------------------------------------------------------
-- PROCEDURE   : UPDATE_PERSON
-- Description : This procedure calls the HRMS public API
--               hr_person_api.update_gb_person  to update
--               person with in a GB legislation  l_supervisor_id
--------------------------------------------------------------
   PROCEDURE update_person
   IS
      x_effective_start_date       DATE;
      x_effective_end_date         DATE;
      x_full_name                  VARCHAR2 (200);
      x_comment_id                 NUMBER (10);
      x_name_combination_warning   BOOLEAN;
      x_assign_payroll_warning     BOOLEAN;
      x_orig_hire_warning          BOOLEAN;
      l_status                     VARCHAR2 (30);
   BEGIN
      g_effective_start_date := NULL;
      g_effective_end_date := NULL;
      x_full_name := NULL;
      x_comment_id := NULL;
      x_name_combination_warning := NULL;
      x_assign_payroll_warning := NULL;
      x_orig_hire_warning := NULL;

      IF g_emp_flag = 'N'
      THEN
         g_employee_number := NULL;
      END IF;

      hr_person_api.update_gb_person
                    (p_validate                      => FALSE,
                     p_effective_date                => g_effective_date,
                     p_datetrack_update_mode         => g_datetrack_update_mode,
                     p_person_id                     => g_person_id,
                     p_object_version_number         => g_object_version_number
                                                                               --,p_person_type_id               => g_person_type_id
      ,
                     p_last_name                     => g_last_name,
                     p_date_of_birth                 => g_dob,
                     p_employee_number               => g_employee_number,
                     p_first_name                    => g_first_name,
                     p_sex                           => g_gender,
                     p_title                         => g_title
                                                               --,p_npw_number                   => g_npw_number
      ,
                     p_effective_start_date          => g_effective_start_date,
                     p_effective_end_date            => g_effective_end_date,
                     p_full_name                     => x_full_name,
                     p_comment_id                    => x_comment_id,
                     p_name_combination_warning      => x_name_combination_warning,
                     p_assign_payroll_warning        => x_assign_payroll_warning,
                     p_orig_hire_warning             => x_orig_hire_warning
                    );
      g_success := 'Y';
      -- Added Commit By Makarandsingh Sisodiya on 22-Sep-2011 as per artifact number artf1586535
      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         g_success := 'N';
         g_error_column_value :=
                           g_error_column_value || ',' || '-UPDATE_GB_PERSON';
         g_error_msg := g_error_msg || ', ' || SUBSTR (SQLERRM, 1, 300);
         g_linecount := g_linecount + 1;
         xxccms_logging_util.log_audit_msg
            (p_transaction_request_id      => g_transaction_request_id,
             p_component_type              => xxccms_logging_util.c_comp_type_conc,
             p_transaction_name            => 'MOD014 - DT020-24 Employee Synchronisation SMS to CCMS',
             p_source_system               => xxccms_logging_util.c_message_type_sms,
             p_source_name                 => xxccms_logging_util.c_message_type_sms,
             p_target_system               => xxccms_logging_util.c_message_type_ebs,
             p_target_name                 => xxccms_logging_util.c_message_type_ccms,
             p_message_source_type         => xxccms_logging_util.c_message_type_plsql,
             p_process_name                => 'xxccms_employeesync_pkg.update_person',
             p_process_stage               => xxccms_logging_util.c_message_type_intermediate,
             p_log_type                    => xxccms_logging_util.c_message_type_error,
             p_record_ref_key              => 'Employee Number',
             p_record_ref_value            => g_employee_number,
             p_message_code                => '60',
             p_message_description         =>    'Error occured while Updating employee with person id '
                                              || g_person_id
                                              || ',refer log for details '
                                              || SUBSTR (SQLERRM, 1, 300),
             p_send_email                  => 'N',
             p_email_id                    => NULL,
             p_time_stamp                  => SYSDATE,
             p_user_name                   => g_created_by,
             p_status                      => l_status
            );
   END update_person;

--------------------------------------------------------------
--------------------------------------------------------------
-- PROCEDURE   : TERMINATE_EMPLOYEE
-- Description : This procedure calls the HRMS public API's
--               hr_ex_employee_api.actual_termination_emp
--               hr_ex_employee_api.final_process_emp
--               to terminate employee .
---------------------------------------------------------------
   PROCEDURE terminate_employee
   IS
      x_last_std_process_date        DATE;
      x_alu_change_warning           VARCHAR2 (200);
      x_dod_warning                  BOOLEAN;
      x_pay_proposal_warning         BOOLEAN;
      x_recruiter_warning            BOOLEAN;
      x_review_warning               BOOLEAN;
      x_interview_warning            BOOLEAN;
      x_event_warning                BOOLEAN;
      x_supervisor_warning           BOOLEAN;
      x_entries_changed_warning      VARCHAR2 (200);
      x_asg_future_changes_warning   BOOLEAN;
      x_last_standard_process_date   DATE;
      x_org_now_no_manager_warning   BOOLEAN;
      g_final_process_date           DATE;
      l_status                       VARCHAR2 (20);
   BEGIN
      x_last_std_process_date := NULL;
      x_alu_change_warning := NULL;
      x_dod_warning := NULL;
      x_pay_proposal_warning := NULL;
      x_recruiter_warning := NULL;
      x_review_warning := NULL;
      x_interview_warning := NULL;
      x_event_warning := NULL;
      x_supervisor_warning := NULL;
      x_entries_changed_warning := NULL;
      x_asg_future_changes_warning := NULL;
      g_last_standard_process_date := NULL;
      hr_ex_employee_api.actual_termination_emp
               (p_validate                        => FALSE,
                p_effective_date                  => g_effective_date,
                p_period_of_service_id            => g_per_service_id,
                p_object_version_number           => g_emp_object_version_number,
                p_actual_termination_date         => g_actual_termination_date,
                p_last_standard_process_date      => g_last_standard_process_date
                                                                                 --,p_person_type_id                in     number   default hr_api.g_number
                                                                                 --,p_assignment_status_type_id     in     number   default hr_api.g_number
                                                                                 --,p_leaving_reason                in     varchar2 default hr_api.g_varchar2
                                                                                 --,p_atd_new                       in     number   default hr_api.g_true_num
                                                                                 --,p_lspd_new                      in     number   default hr_api.g_true_num
      ,
                p_supervisor_warning              => x_supervisor_warning,
                p_event_warning                   => x_event_warning,
                p_interview_warning               => x_interview_warning,
                p_review_warning                  => x_review_warning,
                p_recruiter_warning               => x_recruiter_warning,
                p_asg_future_changes_warning      => x_asg_future_changes_warning,
                p_entries_changed_warning         => x_entries_changed_warning,
                p_pay_proposal_warning            => x_pay_proposal_warning,
                p_dod_warning                     => x_dod_warning,
                p_alu_change_warning              => x_alu_change_warning
               );
      g_success := 'Y';

      BEGIN
         x_entries_changed_warning := NULL;
         x_asg_future_changes_warning := NULL;
         x_org_now_no_manager_warning := NULL;
         g_final_process_date := g_last_standard_process_date;
         hr_ex_employee_api.final_process_emp
               (p_validate                        => FALSE,
                p_period_of_service_id            => g_per_service_id,
                p_object_version_number           => g_emp_object_version_number,
                p_final_process_date              => g_final_process_date,
                p_org_now_no_manager_warning      => x_org_now_no_manager_warning,
                p_asg_future_changes_warning      => x_asg_future_changes_warning,
                p_entries_changed_warning         => x_entries_changed_warning
               );
         g_success := 'Y';
         -- Added Commit By Makarandsingh Sisodiya on 22-Sep-2011 as per artifact number artf1586535
         COMMIT;
      EXCEPTION
         WHEN OTHERS
         THEN
            g_success := 'N';
            g_error_column_value :=
                          g_error_column_value || ',' || '-FINAL_PROCESS_EMP';
            g_error_msg := g_error_msg || ', ' || SUBSTR (SQLERRM, 1, 300);
            g_linecount := g_linecount + 1;
            xxccms_logging_util.log_audit_msg
               (p_transaction_request_id      => g_transaction_request_id,
                p_component_type              => xxccms_logging_util.c_comp_type_conc,
                p_transaction_name            => 'MOD014 - DT020-24 Employee Synchronisation SMS to CCMS',
                p_source_system               => xxccms_logging_util.c_message_type_sms,
                p_source_name                 => xxccms_logging_util.c_message_type_sms,
                p_target_system               => xxccms_logging_util.c_message_type_ebs,
                p_target_name                 => xxccms_logging_util.c_message_type_ccms,
                p_message_source_type         => xxccms_logging_util.c_message_type_plsql,
                p_process_name                => 'xxccms_employeesync_pkg.final_process_emp',
                p_process_stage               => xxccms_logging_util.c_message_type_intermediate,
                p_log_type                    => xxccms_logging_util.c_message_type_error,
                p_record_ref_key              => 'Employee Number',
                p_record_ref_value            => g_employee_number,
                p_message_code                => '63',
                p_message_description         =>    'Unknown error occured while Final proceesing the details of employee with service id'
                                                 || g_per_service_id,
                p_send_email                  => 'N',
                p_email_id                    => NULL,
                p_time_stamp                  => SYSDATE,
                p_user_name                   => g_created_by,
                p_status                      => l_status
               );
      END;
   EXCEPTION
      WHEN OTHERS
      THEN
         g_success := 'N';
         g_error_column_value :=
                         g_error_column_value || ',' || '-TERMINATE_EMPLOYEE';
         g_error_msg := g_error_msg || ', ' || SUBSTR (SQLERRM, 1, 300);
         g_linecount := g_linecount + 1;
         xxccms_logging_util.log_audit_msg
            (p_transaction_request_id      => g_transaction_request_id,
             p_component_type              => xxccms_logging_util.c_comp_type_conc,
             p_transaction_name            => 'MOD014 - DT020-24 Employee Synchronisation SMS to CCMS',
             p_source_system               => xxccms_logging_util.c_message_type_sms,
             p_source_name                 => xxccms_logging_util.c_message_type_sms,
             p_target_system               => xxccms_logging_util.c_message_type_ebs,
             p_target_name                 => xxccms_logging_util.c_message_type_ccms,
             p_message_source_type         => xxccms_logging_util.c_message_type_plsql,
             p_process_name                => 'xxccms_employeesync_pkg.terminate_employee',
             p_process_stage               => xxccms_logging_util.c_message_type_intermediate,
             p_log_type                    => xxccms_logging_util.c_message_type_error,
             p_record_ref_key              => 'Employee Number',
             p_record_ref_value            => g_employee_number,
             p_message_code                => '64',
             p_message_description         =>    'Unknown error occured while Terminating employee service with service id '
                                              || g_per_service_id
                                              || ' ,refer log for details '
                                              || SUBSTR (SQLERRM, 1, 300),
             p_send_email                  => 'N',
             p_email_id                    => NULL,
             p_time_stamp                  => SYSDATE,
             p_user_name                   => g_created_by,
             p_status                      => l_status
            );
   END terminate_employee;

     --------------------------------------------------------------
-- PROCEDURE   : REHIRE_EMPLOYEE
-- Description : This procedure calls the HRMS public API's
--               hr_employee_api.re_hire_ex_employee
--
--               to Rehire the ex employee .
---------------------------------------------------------------
   PROCEDURE rehire_employee (
      p_person_id           IN   per_all_assignments_f.person_id%TYPE,
      p_employee_number     IN   NUMBER,
      p_latest_start_date   IN   DATE
   )
   IS
      l_validate                    BOOLEAN        DEFAULT FALSE;
      l_hire_date                   DATE;
      l_person_id                   NUMBER;
      l_per_object_version_number   NUMBER;
      l_person_type_id              NUMBER;
      l_rehire_reason               VARCHAR2 (200);
      l_system_person_type          VARCHAR2 (100);
      l_status_comman               VARCHAR2 (2);
      x_assignment_id               NUMBER;
      x_asg_object_version_number   NUMBER;
      x_per_effective_start_date    DATE;
      x_per_effective_end_date      DATE;
      x_assignment_sequence         NUMBER;
      x_assignment_number           VARCHAR2 (200);
      x_assign_payroll_warning      BOOLEAN;
      x_system_person_type          VARCHAR2 (200);
      l_status                      VARCHAR2 (20);
   BEGIN
      SELECT person_type_id, effective_start_date, object_version_number
        INTO l_person_type_id, l_hire_date, l_per_object_version_number
        FROM per_all_people_f
       WHERE person_id = p_person_id
         AND SYSDATE BETWEEN effective_start_date AND effective_end_date;

      SELECT system_person_type
        INTO l_system_person_type
        FROM per_person_types
       WHERE person_type_id = l_person_type_id;

      SELECT rehire_reason
        INTO l_rehire_reason
        FROM per_people_f
       WHERE person_id = p_person_id
         AND SYSDATE BETWEEN effective_start_date AND effective_end_date;

      IF l_system_person_type = 'EX_EMP'
      THEN
         hr_employee_api.re_hire_ex_employee
                 (p_validate                       => FALSE,     --l_validate,
                  p_hire_date                      => p_latest_start_date,
                  --g_latest_start_date,
                  p_person_id                      => p_person_id,
                  p_per_object_version_number      => l_per_object_version_number,
                  p_rehire_reason                  => l_rehire_reason,
                  p_assignment_id                  => x_assignment_id,
                  p_asg_object_version_number      => x_asg_object_version_number,
                  p_per_effective_start_date       => x_per_effective_start_date,
                  p_per_effective_end_date         => x_per_effective_end_date,
                  p_assignment_sequence            => x_assignment_sequence,
                  p_assignment_number              => x_assignment_number,
                  p_assign_payroll_warning         => x_assign_payroll_warning
                 );
      END IF;

      g_success := 'Y';
   EXCEPTION
      WHEN OTHERS
      THEN
         g_success := 'N';
         g_error_column_value :=
                            g_error_column_value || ',' || '-REHIRE_EMPLOYEE';
         g_error_msg := g_error_msg || ', ' || SUBSTR (SQLERRM, 1, 300);
         g_linecount := g_linecount + 1;
         xxccms_logging_util.log_audit_msg
            (p_transaction_request_id      => g_transaction_request_id,
             p_component_type              => xxccms_logging_util.c_comp_type_conc,
             p_transaction_name            => 'MOD014 - DT020-24 Employee Synchronisation SMS to CCMS',
             p_source_system               => xxccms_logging_util.c_message_type_sms,
             p_source_name                 => xxccms_logging_util.c_message_type_sms,
             p_target_system               => xxccms_logging_util.c_message_type_ebs,
             p_target_name                 => xxccms_logging_util.c_message_type_ccms,
             p_message_source_type         => xxccms_logging_util.c_message_type_plsql,
             p_process_name                => 'xxccms_employeesync_pkg.rehire_employee',
             p_process_stage               => xxccms_logging_util.c_message_type_intermediate,
             p_log_type                    => xxccms_logging_util.c_message_type_error,
             p_record_ref_key              => 'Employee  Number',
             p_record_ref_value            => p_employee_number,
             p_message_code                => '65',
             p_message_description         =>    'Unknowm Error occured while Rehiring the employee '
                                              || p_employee_number
                                              || ' ,refer log for details '
                                              || SUBSTR (SQLERRM, 1, 300),
             p_send_email                  => 'N',
             p_email_id                    => NULL,
             p_time_stamp                  => SYSDATE,
             p_user_name                   => g_created_by,
             p_status                      => l_status
            );
   --ROLLBACK;
   END rehire_employee;

--------------------------------------------------------------
-- PROCEDURE   : REVERSE_TERMINATE_EMPLOYEE
-- Description : This procedure calls the HRMS public API
--               hr_ex_employee_api.reverse_terminate_employee
--               to reverse terminate employee  .
--------------------------------------------------------------
   PROCEDURE reverse_terminate_employee (
      p_person_id                     IN   NUMBER,
      p_employee_number               IN   NUMBER,
      p_actual_termination_date_emp   IN   DATE
   )
   IS
      l_status   VARCHAR2 (20);
   BEGIN
      g_linecount := g_linecount + 1;
      g_procedure_name := 'reverse_terminate_employee';
      hr_ex_employee_api.reverse_terminate_employee
                 (p_validate                     => FALSE,
                  p_person_id                    => p_person_id,
                  p_actual_termination_date      => p_actual_termination_date_emp,
                  p_clear_details                => 'Y'
                 );
      g_success := 'Y';
   EXCEPTION
      WHEN OTHERS
      THEN
         g_success := 'N';
         g_error_column_value :=
                 g_error_column_value || ',' || '-REVERSE_TERMINATE_EMPLOYEE';
         g_error_msg := g_error_msg || ', ' || SUBSTR (SQLERRM, 1, 300);
         g_linecount := g_linecount + 1;
         xxccms_logging_util.log_audit_msg
            (p_transaction_request_id      => g_transaction_request_id,
             p_component_type              => xxccms_logging_util.c_comp_type_conc,
             p_transaction_name            => 'MOD014 - DT020-24 Employee Synchronisation SMS to CCMS',
             p_source_system               => xxccms_logging_util.c_message_type_sms,
             p_source_name                 => xxccms_logging_util.c_message_type_sms,
             p_target_system               => xxccms_logging_util.c_message_type_ebs,
             p_target_name                 => xxccms_logging_util.c_message_type_ccms,
             p_message_source_type         => xxccms_logging_util.c_message_type_plsql,
             p_process_name                => 'xxccms_employeesync_pkg.reverse_terminate_employee',
             p_process_stage               => xxccms_logging_util.c_message_type_intermediate,
             p_log_type                    => xxccms_logging_util.c_message_type_error,
             p_record_ref_key              => 'Employee Number',
             p_record_ref_value            => p_employee_number,
             p_message_code                => '68',
             p_message_description         =>    'Unknown Error occured while reverse termination employee,refer logs for details'
                                              || SUBSTR (SQLERRM, 1, 200),
             p_send_email                  => 'N',
             p_email_id                    => NULL,
             p_time_stamp                  => SYSDATE,
             p_user_name                   => g_created_by,
             p_status                      => l_status
            );
   END reverse_terminate_employee;
   
   PROCEDURE process_partial_recs
   IS
     CURSOR cur_get_part_recs
     IS
       SELECT stg.rowid row_id,
              papf.person_id,
              papf.business_group_id,
              stg.*
         FROM xxccms_employee_stg stg,
              per_all_people_f papf     
        WHERE record_status  = 'PARTIAL'
          AND papf.employee_number = stg.employee_number;
          --AND SYSDATE BETWEEN papf.effective_start_date AND papf.effective_end_date; -- Commented by Makarandsingh Sisodiya on 10-10-2011
          
    lr_part_rec                      cur_get_part_recs%ROWTYPE;
    l_supervisor_id                  NUMBER;
    l_supervisor_assignment_id       NUMBER;
    l_assign_num_error               NUMBER;
    l_error_msg_001                  VARCHAR2 (200):= 'Business_group  cannot be blank.';
    l_error_msg_002                  VARCHAR2 (200):= 'Business_group does not exist.';
    l_error_msg_003                  VARCHAR2 (200):= 'Pmp_number cannot be blank.';
    l_error_msg_004                  VARCHAR2 (200):= 'Person_type_action cannot be blank.';
    l_error_msg_005                  VARCHAR2 (200):= 'Person_type_action does not exist.';
    l_error_msg_006                  VARCHAR2 (200):= 'Last_name cannot be blank.';
    l_error_msg_007                  VARCHAR2 (200):= 'Gender cannot be blank.';
    l_error_msg_008                  VARCHAR2 (200):= 'Gender does not exist.';
    l_error_msg_009                  VARCHAR2 (200):= 'Date_of_birth is invalid.';
    l_error_msg_010                  VARCHAR2 (200):= 'Location does not exist';
    l_error_msg_011                  VARCHAR2 (300):= 'Job does not exist.';
    l_error_msg_012                  VARCHAR2 (300):= 'Supervisor does not exist.';
    l_error_msg_013                  VARCHAR2 (300):= 'Organisation does not exist.';
    l_error_msg_014                  VARCHAR2 (100):= 'Assignment_number does not exist.';
    l_error_msg_015                  VARCHAR2 (500):= 'Person id is null for new employee.';
    l_error_msg_016                  VARCHAR2 (200):= 'Latest_start_date cannot be blank.';
    l_error_msg_017                  VARCHAR2 (100):= 'Object Verson number not found.';
    l_error_msg_018                  VARCHAR2 (500):= 'Person_id is null for new employee.';
    l_error_msg_019                  VARCHAR2 (100):= 'No Assignment Found to this Superrvisor.';
    l_status_err                     VARCHAR2 (30);
    x_effective_start_date           DATE;
    x_effective_end_date             DATE;
    x_cagr_grade_def_id              NUMBER;
    x_cagr_concatenated_segments     VARCHAR2 (100);
    x_concatenated_segments          VARCHAR2 (25);
    x_soft_coding_keyflex_id         NUMBER (10);
    x_comment_id                     NUMBER (10);
    x_no_managers_warning            BOOLEAN;
    x_other_manager_warning          BOOLEAN;
    x_hourly_salaried_warning        BOOLEAN;
    x_gsp_post_process_warning       VARCHAR2 (100);
    x_special_ceiling_step_id        NUMBER;
    x_people_group_id                NUMBER;
    x_group_name                     VARCHAR2 (100);
    x_org_now_no_manager_warning     BOOLEAN;
    x_spp_delete_warning             BOOLEAN;
    x_entries_changed_warning        VARCHAR2 (200);
    x_tax_district_changed_warning   BOOLEAN;
    l_status                         VARCHAR2 (20);
    l_assignment_id                  NUMBER;
    l_ass_object_version_number      NUMBER;
    l_location_id                    NUMBER;
    l_ass_eff_start_date             DATE;
    l_datetrack_update_mode          VARCHAR2(100);
    l_organization_id                NUMBER;  
   BEGIN
        OPEN  cur_get_part_recs;
        LOOP
            BEGIN
                 FETCH cur_get_part_recs INTO lr_part_rec;
                 EXIT WHEN cur_get_part_recs%NOTFOUND;
                 l_location_id:=NULL;
                 l_supervisor_id:=NULL;
                 l_supervisor_assignment_id:=NULL;
                 g_record_valid   := gc_return_true_b;
                                  

                 get_assignment_id (lr_part_rec.person_id,
                                    lr_part_rec.business_group_id,
                                    lr_part_rec.latest_start_date,
                                    lr_part_rec.employee_number,
                                    lr_part_rec.assignment_number,
                                    l_assignment_id,
                                    l_ass_object_version_number,
                                    l_assign_num_error,
                                    l_ass_eff_start_date);
                 

                 IF l_assign_num_error = gc_error_code_no_data_found
                 THEN
                     
                     g_error_column_value := g_error_column_value || ',' || 'ASSIGNMENT_NUMBER';
                     g_error_msg := g_error_msg || ', ' || l_error_msg_014;
                     g_record_valid := gc_return_false_b;
                     xxccms_logging_util.log_audit_msg(p_transaction_request_id      => g_transaction_request_id,
                                                       p_component_type              => xxccms_logging_util.c_comp_type_conc,
                                                       p_transaction_name            => 'MOD014 - DT020-24 Employee Synchronisation SMS to CCMS',
                                                       p_source_system               => xxccms_logging_util.c_message_type_sms,
                                                       p_source_name                 => xxccms_logging_util.c_message_type_sms,
                                                       p_target_system               => xxccms_logging_util.c_message_type_ebs,
                                                       p_target_name                 => xxccms_logging_util.c_message_type_ccms,
                                                       p_message_source_type         => xxccms_logging_util.c_message_type_plsql,
                                                       p_process_name                => 'xxccms_employeesync_pkg.process_partial_recs',
                                                       p_process_stage               => xxccms_logging_util.c_message_type_intermediate,
                                                       p_log_type                    => xxccms_logging_util.c_message_type_warning,
                                                       p_record_ref_key              => 'Employee Number',
                                                       p_record_ref_value            => lr_part_rec.employee_number,
                                                       p_message_code                => '45',
                                                       p_message_description         => l_error_msg_014,
                                                       p_send_email                  => 'N',
                                                       p_email_id                    => NULL,
                                                       p_time_stamp                  => SYSDATE,
                                                       p_user_name                   => g_created_by,
                                                       p_status                      => l_status_err);
                 ELSIF l_assign_num_error = gc_error_code_others
                 THEN
                    
                     g_error_column_value := g_error_column_value || ',' || 'ASSIGNMENT_NUMBER';
                     g_error_msg := g_error_msg || ', ' || SQLERRM;
                     g_record_valid := gc_return_false_b;
                     xxccms_logging_util.log_audit_msg(p_transaction_request_id      => g_transaction_request_id,
                                                       p_component_type              => xxccms_logging_util.c_comp_type_conc,
                                                       p_transaction_name            => 'MOD014 - DT020-24 Employee Synchronisation SMS to CCMS',
                                                       p_source_system               => xxccms_logging_util.c_message_type_sms,
                                                       p_source_name                 => xxccms_logging_util.c_message_type_sms,
                                                       p_target_system               => xxccms_logging_util.c_message_type_ebs,
                                                       p_target_name                 => xxccms_logging_util.c_message_type_ccms,
                                                       p_message_source_type         => xxccms_logging_util.c_message_type_plsql,
                                                       p_process_name                => 'xxccms_employeesync_pkg.process_partial_recs',
                                                       p_process_stage               => xxccms_logging_util.c_message_type_intermediate,
                                                       p_log_type                    => xxccms_logging_util.c_message_type_error,
                                                       p_record_ref_key              => 'Employee Number',
                                                       p_record_ref_value            => lr_part_rec.employee_number,
                                                       p_message_code                => '46',
                                                       p_message_description         => 'Unknown Error occured while validating Assignment number,refer log for details'
                                                                                       || SUBSTR (SQLERRM,1,100),
                                                       p_send_email                  => 'N',
                                                       p_email_id                    => NULL,
                                                       p_time_stamp                  => SYSDATE,
                                                       p_user_name                   => g_created_by,
                                                       p_status                      => l_status_err);
                 END IF;
                 
                 
                 IF lr_part_rec.supervisor IS NOT NULL
                 THEN
                     l_supervisor_id := get_supervisor_id (lr_part_rec.supervisor,
                                                           lr_part_rec.employee_number,
                                                           lr_part_rec.effective_start_date,
                                                           lr_part_rec.business_group_id);
                                         
                     IF l_supervisor_id IS NOT NULL
                     THEN
                         
                         get_super_assignment_id (l_supervisor_id,
                                                  lr_part_rec.business_group_id,
                                                  lr_part_rec.effective_start_date,
                                                  lr_part_rec.employee_number,
                                                  l_supervisor_assignment_id,
                                                  l_assign_num_error);
                                          
                         IF l_assign_num_error = gc_error_code_no_data_found
                         THEN
                             
                             g_error_column_value := g_error_column_value || ',' || 'ASSIGNMENT_NUMBER';
                             g_error_msg := g_error_msg || ', ' || l_error_msg_014;
                             g_record_valid := gc_return_false_b;
                             xxccms_logging_util.log_audit_msg(p_transaction_request_id      => g_transaction_request_id,
                                                               p_component_type              => xxccms_logging_util.c_comp_type_conc,
                                                               p_transaction_name            => 'MOD014 - DT020-24 Employee Synchronisation SMS to CCMS',
                                                               p_source_system               => xxccms_logging_util.c_message_type_sms,
                                                               p_source_name                 => xxccms_logging_util.c_message_type_sms,
                                                               p_target_system               => xxccms_logging_util.c_message_type_ebs,
                                                               p_target_name                 => xxccms_logging_util.c_message_type_ccms,
                                                               p_message_source_type         => xxccms_logging_util.c_message_type_plsql,
                                                               p_process_name                => 'xxccms_employeesync_pkg.process_partial_recs',
                                                               p_process_stage               => xxccms_logging_util.c_message_type_intermediate,
                                                               p_log_type                    => xxccms_logging_util.c_message_type_error,
                                                               p_record_ref_key              => 'Employee Number',
                                                               p_record_ref_value            => lr_part_rec.employee_number,
                                                               p_message_code                => '51',
                                                               p_message_description         => l_error_msg_019,
                                                               p_send_email                  => 'N',
                                                               p_email_id                    => NULL,
                                                               p_time_stamp                  => SYSDATE,
                                                               p_user_name                   => g_created_by,
                                                               p_status                      => l_status_err);
                         ELSIF l_assign_num_error = gc_error_code_others
                         THEN
                             
                             g_error_column_value := g_error_column_value || ',' || 'ASSIGNMENT_NUMBER';
                             g_error_msg := g_error_msg || ', ' || SQLERRM;
                             g_record_valid := gc_return_false_b;
                             xxccms_logging_util.log_audit_msg(p_transaction_request_id      => g_transaction_request_id,
                                                               p_component_type              => xxccms_logging_util.c_comp_type_conc,
                                                               p_transaction_name            => 'MOD014 - DT020-24 Employee Synchronisation SMS to CCMS',
                                                               p_source_system               => xxccms_logging_util.c_message_type_sms,
                                                               p_source_name                 => xxccms_logging_util.c_message_type_sms,
                                                               p_target_system               => xxccms_logging_util.c_message_type_ebs,
                                                               p_target_name                 => xxccms_logging_util.c_message_type_ccms,
                                                               p_message_source_type         => xxccms_logging_util.c_message_type_plsql,
                                                               p_process_name                => 'xxccms_employeesync_pkg.process_partial_recs',
                                                               p_process_stage               => xxccms_logging_util.c_message_type_intermediate,
                                                               p_log_type                    => xxccms_logging_util.c_message_type_error,
                                                               p_record_ref_key              => 'Employee Number',
                                                               p_record_ref_value            => lr_part_rec.employee_number,
                                                               p_message_code                => '52',
                                                               p_message_description         => 'Unknown error occured while fetching Supervisor assignment id,refer log for details'
                                                                                                || SUBSTR (SQLERRM,1,100),
                                                               p_send_email                  => 'N',
                                                               p_email_id                    => NULL,
                                                               p_time_stamp                  => SYSDATE,
                                                               p_user_name                   => g_created_by,
                                                               p_status                      => l_status_err);
                         END IF;
                     ELSE
                         
                         l_supervisor_assignment_id := NULL;
                     END IF;
                END IF;
                                
                IF lr_part_rec.location IS NOT NULL
                THEN
                   
                    l_location_id := get_location_id (lr_part_rec.location,
                                                      lr_part_rec.business_group_id,
                                                      lr_part_rec.employee_number);
                    
                    IF l_location_id = gc_error_code_no_data_found
                    THEN
                        
                        l_location_id := NULL;
                        g_error_column_value := g_error_column_value || ',' || 'LOCATION';
                        g_error_msg := g_error_msg || ', ' || l_error_msg_010;
                        g_record_valid := gc_return_false_b;
                        xxccms_logging_util.log_audit_msg(p_transaction_request_id      => g_transaction_request_id,
                                                          p_component_type              => xxccms_logging_util.c_comp_type_conc,
                                                          p_transaction_name            => 'MOD014 - DT020-24 Employee Synchronisation SMS to CCMS',
                                                          p_source_system               => xxccms_logging_util.c_message_type_sms,
                                                          p_source_name                 => xxccms_logging_util.c_message_type_sms,
                                                          p_target_system               => xxccms_logging_util.c_message_type_ebs,
                                                          p_target_name                 => xxccms_logging_util.c_message_type_ccms,
                                                          p_message_source_type         => xxccms_logging_util.c_message_type_plsql,
                                                          p_process_name                => 'xxccms_employeesync_pkg.main',
                                                          p_process_stage               => xxccms_logging_util.c_message_type_intermediate,
                                                          p_log_type                    => xxccms_logging_util.c_message_type_error,
                                                          p_record_ref_key              => 'Employee Number',
                                                          p_record_ref_value            => lr_part_rec.employee_number,
                                                          p_message_code                => '36',
                                                          p_message_description         => l_error_msg_010,
                                                          p_send_email                  => 'N',
                                                          p_email_id                    => NULL,
                                                          p_time_stamp                  => SYSDATE,
                                                          p_user_name                   => g_created_by,
                                                          p_status                      => l_status_err);
                    ELSIF l_location_id = gc_error_code_others
                    THEN
                        
                        l_location_id := NULL;
                        g_error_column_value := g_error_column_value || ',' || 'LOCATION';
                        g_error_msg := g_error_msg || ', ' || SQLERRM;
                        g_record_valid := gc_return_false_b;
                    END IF;
                ELSE
                     
                     l_location_id := NULL;
                END IF;
      
                
                l_organization_id := get_org_id (lr_part_rec.employee_number);
                   
                g_ass_success                 := 'N';
                x_cagr_grade_def_id           := NULL;
                x_cagr_concatenated_segments  := NULL;
                x_concatenated_segments       := NULL;
                x_soft_coding_keyflex_id      := NULL;
                x_comment_id                  := NULL;
                g_effective_start_date        := NULL;
                g_effective_end_date          := NULL;
                x_no_managers_warning         := NULL;
                x_other_manager_warning       := NULL;
                x_hourly_salaried_warning     := NULL;
                x_gsp_post_process_warning    := NULL;
                g_linecount                   := g_linecount + 1;
                g_procedure_name              := 'update_employee_asg';
             
                -- Update employee Assignment
                IF to_char(lr_part_rec.effective_end_date,'DD-MON-RRRR') > to_char(l_ass_eff_start_date ,'DD-MON-RRRR')
                THEN
                    
                    l_datetrack_update_mode := 'CORRECTION';
                ELSE
                    
                    l_datetrack_update_mode := 'UPDATE';
                END IF;
               
                hr_assignment_api.update_emp_asg(p_validate                        => FALSE,
                                                 p_effective_date                  => lr_part_rec.latest_start_date,
                                                 p_datetrack_update_mode           => l_datetrack_update_mode,
                                                 p_assignment_id                   => l_assignment_id,
                                                 p_object_version_number           => l_ass_object_version_number,
                                                 p_supervisor_id                   => l_supervisor_id,
                                                 p_assignment_number               => lr_part_rec.assignment_number,
                                                 p_supervisor_assignment_id        => l_supervisor_assignment_id,
                                                 p_cagr_grade_def_id               => x_cagr_grade_def_id,
                                                 p_cagr_concatenated_segments      => x_cagr_concatenated_segments,
                                                 p_concatenated_segments           => x_concatenated_segments,
                                                 p_soft_coding_keyflex_id          => x_soft_coding_keyflex_id,
                                                 p_comment_id                      => x_comment_id,
                                                 p_effective_start_date            => lr_part_rec.effective_start_date,
                                                 p_effective_end_date              => lr_part_rec.effective_end_date,
                                                 p_no_managers_warning             => x_no_managers_warning,
                                                 p_other_manager_warning           => x_other_manager_warning,
                                                 p_hourly_salaried_warning         => x_hourly_salaried_warning,
                                                 p_gsp_post_process_warning        => x_gsp_post_process_warning);
                BEGIN  
                     x_special_ceiling_step_id := NULL;
                     x_soft_coding_keyflex_id := NULL;
                     x_people_group_id := NULL;
                     x_group_name := NULL;
                     g_effective_start_date := NULL;
                     g_effective_end_date := NULL;
                     x_org_now_no_manager_warning := NULL;
                     x_other_manager_warning := NULL;
                     x_spp_delete_warning := NULL;
                     x_entries_changed_warning := NULL;
                     x_tax_district_changed_warning := NULL;
                     x_concatenated_segments := NULL;
                     x_gsp_post_process_warning := NULL;
                     g_linecount := g_linecount + 1;
                     g_procedure_name := 'update_employee_asg_criteria';
                     
                     hr_assignment_api.update_emp_asg_criteria(p_effective_date                    => lr_part_rec.latest_start_date,
                                                               p_datetrack_update_mode             => 'CORRECTION',
                                                               p_assignment_id                     => l_assignment_id,
                                                               p_validate                          => FALSE,
                                                               p_called_from_mass_update           => FALSE,                                                         
                                                               p_location_id                       => l_location_id,
                                                               p_organization_id                   => l_organization_id,
                                                               p_supervisor_assignment_id          => l_supervisor_assignment_id,
                                                               p_object_version_number             => l_ass_object_version_number,
                                                               p_special_ceiling_step_id           => x_special_ceiling_step_id,
                                                               p_people_group_id                   => x_people_group_id,
                                                               p_soft_coding_keyflex_id            => x_soft_coding_keyflex_id,
                                                               p_group_name                        => x_group_name,
                                                               p_effective_start_date              => lr_part_rec.effective_start_date,
                                                               p_effective_end_date                => lr_part_rec.effective_end_date,
                                                               p_org_now_no_manager_warning        => x_org_now_no_manager_warning,
                                                               p_other_manager_warning             => x_other_manager_warning,
                                                               p_spp_delete_warning                => x_spp_delete_warning,
                                                               p_entries_changed_warning           => x_entries_changed_warning,
                                                               p_tax_district_changed_warning      => x_tax_district_changed_warning,
                                                               p_concatenated_segments             => x_concatenated_segments,
                                                               p_gsp_post_process_warning          => x_gsp_post_process_warning);
                     g_ass_success := 'Y';
                EXCEPTION WHEN OTHERS
                THEN
                    
                    g_record_valid := gc_return_false_b;
                    g_error_column_value :=
                    g_error_column_value || ',' || '-UPDATE_GB_EMP_ASG_CRITERIA';
                    g_error_msg := g_error_msg || ', ' || SUBSTR (SQLERRM, 1, 300);
                    g_linecount := g_linecount + 1;
                    xxccms_logging_util.log_audit_msg(p_transaction_request_id      => g_transaction_request_id,
                                                      p_component_type              => xxccms_logging_util.c_comp_type_conc,
                                                      p_transaction_name            => 'MOD014 - DT020-24 Employee Synchronisation SMS to CCMS',
                                                      p_source_system               => xxccms_logging_util.c_message_type_sms,
                                                      p_source_name                 => xxccms_logging_util.c_message_type_sms,
                                                      p_target_system               => xxccms_logging_util.c_message_type_ebs,
                                                      p_target_name                 => xxccms_logging_util.c_message_type_ccms,
                                                      p_message_source_type         => xxccms_logging_util.c_message_type_plsql,
                                                      p_process_name                => 'xxccms_employeesync_pkg.update_emp_asg_criteria',
                                                      p_process_stage               => xxccms_logging_util.c_message_type_intermediate,
                                                      p_log_type                    => xxccms_logging_util.c_message_type_error,
                                                      p_record_ref_key              => 'Employee Number',
                                                      p_record_ref_value            => lr_part_rec.employee_number,
                                                      p_message_code                => '61',
                                                      p_message_description         =>    'Error occured while updating employee with Assignment id '
                                                                                     || g_assignment_id
                                                                                     || ' ,refer log for details '
                                                                                     || SUBSTR (SQLERRM, 1, 300),
                                                      p_send_email                  => 'N',
                                                      p_email_id                    => NULL,
                                                      p_time_stamp                  => SYSDATE,
                                                      p_user_name                   => g_created_by,
                                                      p_status                      => l_status);
                END;
           --g_ass_success := 'Y';
            EXCEPTION WHEN OTHERS
            THEN
                
                g_record_valid := gc_return_false_b;
                g_error_column_value := g_error_column_value || ',' || '-UPDATE_GB_EMP_ASG';
                g_error_msg := g_error_msg || ', ' || SUBSTR (SQLERRM, 1, 300);
                g_linecount := g_linecount + 1;
                xxccms_logging_util.log_audit_msg(p_transaction_request_id      => g_transaction_request_id,
                                                  p_component_type              => xxccms_logging_util.c_comp_type_conc,
                                                  p_transaction_name            => 'MOD014 - DT020-24 Employee Synchronisation SMS to CCMS',
                                                  p_source_system               => xxccms_logging_util.c_message_type_sms,
                                                  p_source_name                 => xxccms_logging_util.c_message_type_sms,
                                                  p_target_system               => xxccms_logging_util.c_message_type_ebs,
                                                  p_target_name                 => xxccms_logging_util.c_message_type_ccms,
                                                  p_message_source_type         => xxccms_logging_util.c_message_type_plsql,
                                                  p_process_name                => 'xxccms_employeesync_pkg.update_employee_asg',
                                                  p_process_stage               => xxccms_logging_util.c_message_type_intermediate,
                                                  p_log_type                    => xxccms_logging_util.c_message_type_error,
                                                  p_record_ref_key              => 'Employee Number',
                                                  p_record_ref_value            => lr_part_rec.employee_number,
                                                  p_message_code                => '62',
                                                  p_message_description         =>    'Error occured while updating employee with Assignment id '
                                                                                 || g_assignment_id
                                                                                 || ' ,refer log for details'
                                                                                 || SUBSTR (SQLERRM, 1, 200),
                                                  p_send_email                  => 'N',
                                                  p_email_id                    => NULL,
                                                  p_time_stamp                  => SYSDATE,
                                                  p_user_name                   => g_created_by,
                                                  p_status                      => l_status);
            END;
            
            IF g_record_valid = gc_return_true_b 
            THEN
                -- Partial record no need to update counters.. just update the status
                
                IF lr_part_rec.record_status='PARTIAL'
                THEN
                    
                    NULL;
                ELSE
                    
                    g_rec_valid := g_rec_valid+1;
                END IF;
                    
                UPDATE xxccms_employee_stg
                   SET record_status = 'PROCESSED'
                 WHERE rowid = lr_part_rec.row_id;
                   
            ELSIF g_record_valid = gc_return_false_b 
            THEN
                
                IF lr_part_rec.record_status='PARTIAL'
                THEN
                    
                    g_rec_valid   := g_rec_valid-1;
                    g_rec_invalid := g_rec_invalid+1;
                ELSE
                    
                    g_rec_invalid := g_rec_invalid+1;
                END IF;
                
                UPDATE xxccms_employee_stg
                   SET record_status = 'ERROR'
                 WHERE rowid = lr_part_rec.row_id;                         
            END IF;
        COMMIT; 
         
        END LOOP;
        
        CLOSE cur_get_part_recs;     
        
   END process_partial_recs;
   
   /****************************************************************************************************
-- Procedure: MAIN
-- Description: This procedure calls the API's and inserts the Employee in the HR base table .
-- and Called from Concurrent Program.
-- Parameters:
-- Name                  IN/OUT   Description
-- x_errbuf               OUT      Error Message
-- x_retcode              OUT      Error Code
*****************************************************************************************************/
   PROCEDURE main (x_errbuf OUT VARCHAR2, x_retcode OUT NUMBER)
   IS
      --
      -- Cursor declaration.
      --
      -- Cursor to get all legacy records in staging table.
      CURSOR validate_cur
      IS
         SELECT   rowid,business_group, last_name, first_name, title, gender,
                  person_type_action, employee_number, dob,
                  effective_start_date, effective_end_date,
                  latest_start_date, ORGANIZATION, assignment_number,
--job,  -- Commented by Makarandsingh Sisodiya on 12-Sept-2011 as per new Functional Specification Verison V_1.4_Issued
                  LOCATION, supervisor, status, person_update,
                  assignment_update, record_status, source_timestamp,
                  record_type
             FROM xxccms_employee_stg
            WHERE record_status = 'NEW'
         ORDER BY source_timestamp;

      --FOR UPDATE OF record_status;

      --
      -- local variables declaration
      --
      l_emp_num            NUMBER;
      l_sys_per_type       VARCHAR2 (20);
      l_last_update_date   DATE;
      l_user_per_type      VARCHAR2 (50);
      l_emp_flg            VARCHAR2 (2);
      l_new_emp_cwk_flag   VARCHAR2 (2);
      l_error_code         NUMBER;
      l_rec_grade_id       NUMBER;
      l_status             VARCHAR2 (2);
      l_db_status          VARCHAR2 (2);
      l_total_records      NUMBER;
      --l_rec_invalid        NUMBER;
      --l_rec_valid          NUMBER;
      l_errbuf             VARCHAR2 (1000);
      l_retcode            NUMBER;
      l_new_emp            VARCHAR2 (2);
      --
      -- Error messages
      --
      l_error_msg_001      VARCHAR2 (200)
                                        := 'Business_group  cannot be blank.';
      l_error_msg_002      VARCHAR2 (200) := 'Business_group does not exist.';
      l_error_msg_003      VARCHAR2 (200)  := 'Pmp_number cannot be blank.';
      l_error_msg_004      VARCHAR2 (200)
                                     := 'Person_type_action cannot be blank.';
      l_error_msg_005      VARCHAR2 (200)
                                      := 'Person_type_action does not exist.';
      l_error_msg_006      VARCHAR2 (200)  := 'Last_name cannot be blank.';
      l_error_msg_007      VARCHAR2 (200)  := 'Gender cannot be blank.';
      l_error_msg_008      VARCHAR2 (200)  := 'Gender does not exist.';
      l_error_msg_009      VARCHAR2 (200)  := 'Date_of_birth is invalid.';
      l_error_msg_010      VARCHAR2 (200)  := 'Location does not exist';
      l_error_msg_011      VARCHAR2 (300)  := 'Job does not exist.';
      l_error_msg_012      VARCHAR2 (300)  := 'Supervisor does not exist.';
      l_error_msg_013      VARCHAR2 (300)  := 'Organisation does not exist.';
      l_error_msg_014      VARCHAR2 (100)
                                       := 'Assignment_number does not exist.';
      l_error_msg_015      VARCHAR2 (500)
                                     := 'Person id is null for new employee.';
      l_error_msg_016      VARCHAR2 (200)
                                      := 'Latest_start_date cannot be blank.';
      l_error_msg_017      VARCHAR2 (100)
                                         := 'Object Verson number not found.';
      l_error_msg_018      VARCHAR2 (500)
                                     := 'Person_id is null for new employee.';
      l_error_msg_019      VARCHAR2 (100)
                                := 'No Assignment Found to this Superrvisor.';
      --l_count_att          xxccms_err_log.attribute3%TYPE;
      l_status_err         VARCHAR2 (30);
      l_err_count          NUMBER;
   BEGIN
      g_rec_invalid := 0;
      g_rec_valid := 0;
      l_total_records := 0;
      --l_count_att := 0;
      g_effective_date := TRUNC (SYSDATE);
      g_procedure_name := 'employee_main';
      l_err_count := 0;

--------------------------------------------------------------------------------

      --
      -- Counting the total number of records in the staging table with record_status as 'NEW'
      --
      SELECT COUNT (1)
        INTO l_total_records
        FROM xxccms_employee_stg
       WHERE record_status = 'NEW';

      FOR validate_rec IN validate_cur
      LOOP
         g_record_valid := gc_return_true_b;
         g_error_column_value := NULL;
         l_error_code := NULL;
         g_error_msg := NULL;
         g_job_id := NULL;
         g_location_id := NULL;
         g_supervisor_id := NULL;
         g_organization_id := NULL;
         g_linecount := g_linecount + 1;
         g_datetrack_update_mode := 'UPDATE';
--       g_actual_termination_date := SYSDATE;
         g_actual_termination_date := validate_rec.effective_end_date;
         g_final_process_date := SYSDATE;
         g_last_standard_process_date := SYSDATE;
         g_success := 'Y';
         g_ass_success := 'Y';
         g_all_attr2 := NULL;
         g_all_attr3 := NULL;
         g_all_attr1 := NULL;
         l_last_update_date := NULL;
--------------------------------------------------------------------------------
--ERROR LOG :line
--------------------------------------------------------------------------------
         xxccms_logging_util.log_audit_msg
            (p_transaction_request_id      => g_transaction_request_id,
             p_component_type              => xxccms_logging_util.c_comp_type_conc,
             p_transaction_name            => 'MOD014 - DT020-24 Employee Synchronisation SMS to CCMS',
             p_source_system               => xxccms_logging_util.c_message_type_sms,
             p_source_name                 => xxccms_logging_util.c_message_type_sms,
             p_target_system               => xxccms_logging_util.c_message_type_ebs,
             p_target_name                 => xxccms_logging_util.c_message_type_ccms,
             p_message_source_type         => xxccms_logging_util.c_message_type_plsql,
             p_process_name                => 'xxccms_employeesync_pkg.main',
             p_process_stage               => xxccms_logging_util.c_message_type_start,
             p_log_type                    => xxccms_logging_util.c_message_type_info,
             p_record_ref_key              => 'Employee Number',
             p_record_ref_value            => validate_rec.employee_number,
             p_message_code                => '1',
             p_message_description         => 'Start of xxccms_employeesync_pkg.main package',
             p_send_email                  => 'N',
             p_email_id                    => NULL,
             p_time_stamp                  => SYSDATE,
             p_user_name                   => g_created_by,
             p_status                      => l_status_err
            );

           --SAVEPOINT stagging_err;
    -- Commeneted By Makarandsingh Sisodiya on 22-Sep-2011 as per artifact number artf1586535
---------------------------------------------------------------------------------
--  CUSTOM VALIDATIONS FOR EMPLOYEE
---------------------------------------------------------------------------------
 --
 -- Check the staging table status field.
 --
         IF UPPER (validate_rec.status) = 'ACTIVE'
         THEN
            l_status := 'Y';
         ELSIF UPPER (validate_rec.status) = 'INACTIVE'
         THEN
            l_status := 'N';
         END IF;

---------------------------------------------------------------------------------
--V01. Validation for mandatory field BUSINESS_GROUP
---------------------------------------------------------------------------------
         g_bookmark := 'Calling Business Group Validation Function';
         g_procedure_name := 'get_business_group_id';

         IF validate_rec.business_group IS NOT NULL
         THEN
            g_business_group_id := get_business_group_id (g_employee_number);

            IF g_business_group_id = gc_error_code_no_data_found
            THEN
               g_business_group_id := NULL;
               g_error_column_value :=
                              g_error_column_value || ',' || 'BUSINESS_GROUP';
               g_error_msg := g_error_msg || ', ' || l_error_msg_002;
               g_record_valid := gc_return_false_b;
               g_linecount := g_linecount + 1;
               xxccms_logging_util.log_audit_msg
                  (p_transaction_request_id      => g_transaction_request_id,
                   p_component_type              => xxccms_logging_util.c_comp_type_conc,
                   p_transaction_name            => 'MOD014 - DT020-24 Employee Synchronisation SMS to CCMS',
                   p_source_system               => xxccms_logging_util.c_message_type_sms,
                   p_source_name                 => xxccms_logging_util.c_message_type_sms,
                   p_target_system               => xxccms_logging_util.c_message_type_ebs,
                   p_target_name                 => xxccms_logging_util.c_message_type_ccms,
                   p_message_source_type         => xxccms_logging_util.c_message_type_plsql,
                   p_process_name                => 'xxccms_employeesync_pkg.main',
                   p_process_stage               => xxccms_logging_util.c_message_type_intermediate,
                   p_log_type                    => xxccms_logging_util.c_message_type_info,
                   p_record_ref_key              => 'Employee Number',
                   p_record_ref_value            => validate_rec.employee_number,
                   p_message_code                => '4',
                   p_message_description         => l_error_msg_002,
                   p_send_email                  => 'N',
                   p_email_id                    => NULL,
                   p_time_stamp                  => SYSDATE,
                   p_user_name                   => g_created_by,
                   p_status                      => l_status_err
                  );
            ELSIF g_business_group_id = gc_error_code_others
            THEN
               g_business_group_id := NULL;
               g_error_column_value :=
                              g_error_column_value || ',' || 'BUSINESS_GROUP';
               g_error_msg := g_error_msg || ', ' || SQLERRM;
               g_record_valid := gc_return_false_b;
               g_linecount := g_linecount + 1;
               xxccms_logging_util.log_audit_msg
                  (p_transaction_request_id      => g_transaction_request_id,
                   p_component_type              => xxccms_logging_util.c_comp_type_conc,
                   p_transaction_name            => 'MOD014 - DT020-24 Employee Synchronisation SMS to CCMS',
                   p_source_system               => xxccms_logging_util.c_message_type_sms,
                   p_source_name                 => xxccms_logging_util.c_message_type_sms,
                   p_target_system               => xxccms_logging_util.c_message_type_ebs,
                   p_target_name                 => xxccms_logging_util.c_message_type_ccms,
                   p_message_source_type         => xxccms_logging_util.c_message_type_plsql,
                   p_process_name                => 'xxccms_employeesync_pkg.main',
                   p_process_stage               => xxccms_logging_util.c_message_type_intermediate,
                   p_log_type                    => xxccms_logging_util.c_message_type_warning,
                   p_record_ref_key              => 'Employee Number',
                   p_record_ref_value            => validate_rec.employee_number,
                   p_message_code                => '5',
                   p_message_description         =>    'Unknown Error has occured while fetching buisnees group id, refer log for details'
                                                    || SUBSTR (SQLERRM, 1,
                                                               200),
                   p_send_email                  => 'N',
                   p_email_id                    => NULL,
                   p_time_stamp                  => SYSDATE,
                   p_user_name                   => g_created_by,
                   p_status                      => l_status_err
                  );
            END IF;
         ELSE
            g_business_group_id := NULL;
            g_error_column_value :=
                              g_error_column_value || ',' || 'BUSINESS_GROUP';
            g_error_msg := g_error_msg || ', ' || l_error_msg_001;
            g_record_valid := gc_return_false_b;
            g_linecount := g_linecount + 1;
            xxccms_logging_util.log_audit_msg
               (p_transaction_request_id      => g_transaction_request_id,
                p_component_type              => xxccms_logging_util.c_comp_type_conc,
                p_transaction_name            => 'MOD014 - DT020-24 Employee Synchronisation SMS to CCMS',
                p_source_system               => xxccms_logging_util.c_message_type_sms,
                p_source_name                 => xxccms_logging_util.c_message_type_sms,
                p_target_system               => xxccms_logging_util.c_message_type_ebs,
                p_target_name                 => xxccms_logging_util.c_message_type_ccms,
                p_message_source_type         => xxccms_logging_util.c_message_type_plsql,
                p_process_name                => 'xxccms_employeesync_pkg.main',
                p_process_stage               => xxccms_logging_util.c_message_type_intermediate,
                p_log_type                    => xxccms_logging_util.c_message_type_error,
                p_record_ref_key              => 'Employee Number',
                p_record_ref_value            => validate_rec.employee_number,
                p_message_code                => '6',
                p_message_description         => l_error_msg_001,
                p_send_email                  => 'N',
                p_email_id                    => NULL,
                p_time_stamp                  => SYSDATE,
                p_user_name                   => g_created_by,
                p_status                      => l_status_err
               );
         END IF;

---------------------------------------------------------------------------------
-- V02. EMPLOYEE NUMBER validation.
---------------------------------------------------------------------------------
         g_bookmark := 'Calling Employee Validation Procedure';
         g_procedure_name := 'val_emp_num';

         IF validate_rec.employee_number IS NOT NULL
         THEN
            g_employee_number := validate_rec.employee_number;
            val_emp_num (g_business_group_id,
                         g_employee_number,
                         g_effective_date,
                         validate_rec.person_type_action,
                         g_person_id,
                         g_object_version_number,
                         g_sys_per_type,
                         g_user_per_type,
                         l_last_update_date,
                         g_emp_flag,
                         g_new_emp_cwk_flag,
                         l_error_code
                        );

            IF l_error_code = gc_error_code_no_data_found
            THEN
               l_new_emp := 'T';
               l_error_code := NULL;
               -- g_effective_date     := validate_rec.effective_start_date;
               --g_record_valid       := gc_return_false_b;
               g_linecount := g_linecount + 1;
               xxccms_logging_util.log_audit_msg
                  (p_transaction_request_id      => g_transaction_request_id,
                   p_component_type              => xxccms_logging_util.c_comp_type_conc,
                   p_transaction_name            => 'MOD014 - DT020-24 Employee Synchronisation SMS to CCMS',
                   p_source_system               => xxccms_logging_util.c_message_type_sms,
                   p_source_name                 => xxccms_logging_util.c_message_type_sms,
                   p_target_system               => xxccms_logging_util.c_message_type_ebs,
                   p_target_name                 => xxccms_logging_util.c_message_type_ccms,
                   p_message_source_type         => xxccms_logging_util.c_message_type_plsql,
                   p_process_name                => 'xxccms_employeesync_pkg.main',
                   p_process_stage               => xxccms_logging_util.c_message_type_intermediate,
                   p_log_type                    => xxccms_logging_util.c_message_type_info,
                   p_record_ref_key              => 'Employee Number',
                   p_record_ref_value            => validate_rec.employee_number,
                   p_message_code                => '9',
                   p_message_description         => 'NO Data Found while validating the employee',
                   p_send_email                  => 'N',
                   p_email_id                    => NULL,
                   p_time_stamp                  => SYSDATE,
                   p_user_name                   => g_created_by,
                   p_status                      => l_status_err
                  );
            ELSIF l_error_code = gc_error_code_others
            THEN
               l_error_code := NULL;
               g_error_column_value :=
                             g_error_column_value || ',' || 'employee_number';
               g_error_msg := g_error_msg || ', ' || SQLERRM;
               g_record_valid := gc_return_false_b;
               g_linecount := g_linecount + 1;
               xxccms_logging_util.log_audit_msg
                  (p_transaction_request_id      => g_transaction_request_id,
                   p_component_type              => xxccms_logging_util.c_comp_type_conc,
                   p_transaction_name            => 'MOD014 - DT020-24 Employee Synchronisation SMS to CCMS',
                   p_source_system               => xxccms_logging_util.c_message_type_sms,
                   p_source_name                 => xxccms_logging_util.c_message_type_sms,
                   p_target_system               => xxccms_logging_util.c_message_type_ebs,
                   p_target_name                 => xxccms_logging_util.c_message_type_ccms,
                   p_message_source_type         => xxccms_logging_util.c_message_type_plsql,
                   p_process_name                => 'xxccms_employeesync_pkg.main',
                   p_process_stage               => xxccms_logging_util.c_message_type_intermediate,
                   p_log_type                    => xxccms_logging_util.c_message_type_warning,
                   p_record_ref_key              => 'Employee Number',
                   p_record_ref_value            => validate_rec.employee_number,
                   p_message_code                => '10',
                   p_message_description         =>    'Unknown error occured while calling the validate employee procedure,refer log for details'
                                                    || SUBSTR (SQLERRM, 1,
                                                               100),
                   p_send_email                  => 'N',
                   p_email_id                    => NULL,
                   p_time_stamp                  => SYSDATE,
                   p_user_name                   => g_created_by,
                   p_status                      => l_status_err
                  );
            END IF;
         ELSE
            g_error_column_value :=
                             g_error_column_value || ',' || 'employee_number';
            g_error_msg := g_error_msg || ', ' || l_error_msg_003;
            g_record_valid := gc_return_false_b;
            g_linecount := g_linecount + 1;
            xxccms_logging_util.log_audit_msg
               (p_transaction_request_id      => g_transaction_request_id,
                p_component_type              => xxccms_logging_util.c_comp_type_conc,
                p_transaction_name            => 'MOD014 - DT020-24 Employee Synchronisation SMS to CCMS',
                p_source_system               => xxccms_logging_util.c_message_type_sms,
                p_source_name                 => xxccms_logging_util.c_message_type_sms,
                p_target_system               => xxccms_logging_util.c_message_type_ebs,
                p_target_name                 => xxccms_logging_util.c_message_type_ccms,
                p_message_source_type         => xxccms_logging_util.c_message_type_plsql,
                p_process_name                => 'xxccms_employeesync_pkg.main',
                p_process_stage               => xxccms_logging_util.c_message_type_intermediate,
                p_log_type                    => xxccms_logging_util.c_message_type_error,
                p_record_ref_key              => 'Employee Number',
                p_record_ref_value            => validate_rec.employee_number,
                p_message_code                => '11',
                p_message_description         => l_error_msg_003,
                p_send_email                  => 'N',
                p_email_id                    => NULL,
                p_time_stamp                  => SYSDATE,
                p_user_name                   => g_created_by,
                p_status                      => l_status_err
               );
         END IF;

         -------------------------------------------------------------------
         -- Updating datetrack_update_mode variable as per last_update_date.
         -------------------------------------------------------------------
         -- Updated On 20th Sep 2011 by Makarandsingh Sisodiya as per issues raised in artifact number artf1579423
         IF g_effective_date = TRUNC (l_last_update_date)
         THEN
            g_datetrack_update_mode := 'CORRECTION';
         ELSE
            g_datetrack_update_mode := 'UPDATE';
         END IF;

         ------------------------------------------------------------------------------------------------
         --V03 Setting l_db_status using system_person_type
         ------------------------------------------------------------------------------------------------
         IF UPPER (g_sys_per_type) = 'EX_EMP'
         THEN
            l_db_status := 'N';
         ELSIF UPPER (g_sys_per_type) = 'EMP' OR g_sys_per_type IS NULL
         THEN
            l_db_status := 'Y';
         END IF;

         --
         -- Condition for elemination validations for insertion and updation
         --
         IF    (l_status = 'Y' AND l_db_status = 'Y')
            OR (    l_status = 'Y'
                AND l_db_status = 'N'
                AND validate_rec.record_type = 'I'
               )
         THEN
         ---------------------------------------------------------------------------------
         --V04. Validation for mandatory field latest_start_date
         ---------------------------------------------------------------------------------
            IF validate_rec.latest_start_date IS NULL
            THEN
               g_linecount := g_linecount + 1;
               g_error_column_value :=
                           g_error_column_value || ',' || 'LATEST_START_DATE';
               g_error_msg := g_error_msg || ', ' || l_error_msg_016;
               g_record_valid := gc_return_false_b;
               g_bookmark := 'Latest start date validation';
               xxccms_logging_util.log_audit_msg
                  (p_transaction_request_id      => g_transaction_request_id,
                   p_component_type              => xxccms_logging_util.c_comp_type_conc,
                   p_transaction_name            => 'MOD014 - DT020-24 Employee Synchronisation SMS to CCMS',
                   p_source_system               => xxccms_logging_util.c_message_type_sms,
                   p_source_name                 => xxccms_logging_util.c_message_type_sms,
                   p_target_system               => xxccms_logging_util.c_message_type_ebs,
                   p_target_name                 => xxccms_logging_util.c_message_type_ccms,
                   p_message_source_type         => xxccms_logging_util.c_message_type_plsql,
                   p_process_name                => 'xxccms_employeesync_pkg.main',
                   p_process_stage               => xxccms_logging_util.c_message_type_intermediate,
                   p_log_type                    => xxccms_logging_util.c_message_type_error,
                   p_record_ref_key              => 'Employee Number',
                   p_record_ref_value            => validate_rec.employee_number,
                   p_message_code                => '12',
                   p_message_description         => l_error_msg_016,
                   p_send_email                  => 'N',
                   p_email_id                    => NULL,
                   p_time_stamp                  => SYSDATE,
                   p_user_name                   => g_created_by,
                   p_status                      => l_status_err
                  );
            ELSE
               g_latest_start_date := validate_rec.latest_start_date;
               g_linecount := g_linecount + 1;
               xxccms_logging_util.log_audit_msg
                  (p_transaction_request_id      => g_transaction_request_id,
                   p_component_type              => xxccms_logging_util.c_comp_type_conc,
                   p_transaction_name            => 'MOD014 - DT020-24 Employee Synchronisation SMS to CCMS',
                   p_source_system               => xxccms_logging_util.c_message_type_sms,
                   p_source_name                 => xxccms_logging_util.c_message_type_sms,
                   p_target_system               => xxccms_logging_util.c_message_type_ebs,
                   p_target_name                 => xxccms_logging_util.c_message_type_ccms,
                   p_message_source_type         => xxccms_logging_util.c_message_type_plsql,
                   p_process_name                => 'xxccms_employeesync_pkg.main',
                   p_process_stage               => xxccms_logging_util.c_message_type_intermediate,
                   p_log_type                    => xxccms_logging_util.c_message_type_info,
                   p_record_ref_key              => 'Employee Number',
                   p_record_ref_value            => validate_rec.employee_number,
                   p_message_code                => '13',
                   p_message_description         => 'Latest Start Date available for given employee number',
                   p_send_email                  => 'N',
                   p_email_id                    => NULL,
                   p_time_stamp                  => SYSDATE,
                   p_user_name                   => g_created_by,
                   p_status                      => l_status_err
                  );
            END IF;

---------------------------------------------------------------------------------
--V05. Validation for field EFFECTIVE_START_DATE
---------------------------------------------------------------------------------
            IF validate_rec.effective_start_date IS NOT NULL
            THEN
               g_effective_start_date := validate_rec.effective_start_date;
            ELSE
               g_effective_start_date := SYSDATE;
            END IF;

            IF g_business_group_id IS NOT NULL
            THEN
---------------------------------------------------------------------------------
--V06. Validation for mandatory field ORGANISATION
---------------------------------------------------------------------------------
               g_bookmark := 'Organization Validation';
               g_procedure_name := 'get_org_id';

               IF validate_rec.ORGANIZATION IS NOT NULL
               THEN
                  g_organization_id := get_org_id (g_employee_number);

                  IF g_organization_id = gc_error_code_no_data_found
                  THEN
                     g_organization_id := NULL;
                     g_error_column_value :=
                                g_error_column_value || ',' || 'ORGANISATION';
                     g_error_msg := g_error_msg || ', ' || l_error_msg_013;
                     g_record_valid := gc_return_false_b;
                     g_linecount := g_linecount + 1;
                     xxccms_logging_util.log_audit_msg
                        (p_transaction_request_id      => g_transaction_request_id,
                         p_component_type              => xxccms_logging_util.c_comp_type_conc,
                         p_transaction_name            => 'MOD014 - DT020-24 Employee Synchronisation SMS to CCMS',
                         p_source_system               => xxccms_logging_util.c_message_type_sms,
                         p_source_name                 => xxccms_logging_util.c_message_type_sms,
                         p_target_system               => xxccms_logging_util.c_message_type_ebs,
                         p_target_name                 => xxccms_logging_util.c_message_type_ccms,
                         p_message_source_type         => xxccms_logging_util.c_message_type_plsql,
                         p_process_name                => 'xxccms_employeesync_pkg.main',
                         p_process_stage               => xxccms_logging_util.c_message_type_intermediate,
                         p_log_type                    => xxccms_logging_util.c_message_type_error,
                         p_record_ref_key              => 'Employee Number',
                         p_record_ref_value            => validate_rec.employee_number,
                         p_message_code                => '16',
                         p_message_description         => l_error_msg_013,
                         p_send_email                  => 'N',
                         p_email_id                    => NULL,
                         p_time_stamp                  => SYSDATE,
                         p_user_name                   => g_created_by,
                         p_status                      => l_status_err
                        );
                  ELSIF g_organization_id = gc_error_code_others
                  THEN
                     g_organization_id := NULL;
                     g_error_column_value :=
                                g_error_column_value || ',' || 'ORGANISATION';
                     g_error_msg := g_error_msg || ', ' || SQLERRM;
                     g_record_valid := gc_return_false_b;
                     g_linecount := g_linecount + 1;
                     xxccms_logging_util.log_audit_msg
                        (p_transaction_request_id      => g_transaction_request_id,
                         p_component_type              => xxccms_logging_util.c_comp_type_conc,
                         p_transaction_name            => 'MOD014 - DT020-24 Employee Synchronisation SMS to CCMS',
                         p_source_system               => xxccms_logging_util.c_message_type_sms,
                         p_source_name                 => xxccms_logging_util.c_message_type_sms,
                         p_target_system               => xxccms_logging_util.c_message_type_ebs,
                         p_target_name                 => xxccms_logging_util.c_message_type_ccms,
                         p_message_source_type         => xxccms_logging_util.c_message_type_plsql,
                         p_process_name                => 'xxccms_employeesync_pkg.main',
                         p_process_stage               => xxccms_logging_util.c_message_type_intermediate,
                         p_log_type                    => xxccms_logging_util.c_message_type_warning,
                         p_record_ref_key              => 'Employee Number',
                         p_record_ref_value            => validate_rec.employee_number,
                         p_message_code                => '17',
                         p_message_description         =>    'Unknowm Error occured while validating field Organisation,refer log for details'
                                                          || SUBSTR (SQLERRM,
                                                                     1,
                                                                     100
                                                                    ),
                         p_send_email                  => 'N',
                         p_email_id                    => NULL,
                         p_time_stamp                  => SYSDATE,
                         p_user_name                   => g_created_by,
                         p_status                      => l_status_err
                        );
                  END IF;
               ELSE
                  g_error_column_value :=
                                g_error_column_value || ',' || 'ORGANISATION';
                  g_error_msg :=
                                g_error_msg || ', ' || 'Organization is null';
                  g_record_valid := gc_return_false_b;
                  g_linecount := g_linecount + 1;
                  xxccms_logging_util.log_audit_msg
                     (p_transaction_request_id      => g_transaction_request_id,
                      p_component_type              => xxccms_logging_util.c_comp_type_conc,
                      p_transaction_name            => 'MOD014 - DT020-24 Employee Synchronisation SMS to CCMS',
                      p_source_system               => xxccms_logging_util.c_message_type_sms,
                      p_source_name                 => xxccms_logging_util.c_message_type_sms,
                      p_target_system               => xxccms_logging_util.c_message_type_ebs,
                      p_target_name                 => xxccms_logging_util.c_message_type_ccms,
                      p_message_source_type         => xxccms_logging_util.c_message_type_plsql,
                      p_process_name                => 'xxccms_employeesync_pkg.main',
                      p_process_stage               => xxccms_logging_util.c_message_type_intermediate,
                      p_log_type                    => xxccms_logging_util.c_message_type_error,
                      p_record_ref_key              => 'Employee Number',
                      p_record_ref_value            => validate_rec.employee_number,
                      p_message_code                => '18',
                      p_message_description         =>    'Organisation entered is Null,refer log for details'
                                                       || SUBSTR (SQLERRM,
                                                                  1,
                                                                  100
                                                                 ),
                      p_send_email                  => 'N',
                      p_email_id                    => NULL,
                      p_time_stamp                  => SYSDATE,
                      p_user_name                   => g_created_by,
                      p_status                      => l_status_err
                     );
               END IF;

---------------------------------------------------------------------------------
--V07. Validation for mandatory field person_type_action
---------------------------------------------------------------------------------
               g_linecount := g_linecount + 1;
               g_bookmark := 'Calling person_type_action Validation function';
               g_procedure_name := 'get_person_type_id';

               IF validate_rec.person_type_action IS NOT NULL
               THEN
                  g_person_type_id :=
                     get_person_type_id (g_business_group_id,
                                         validate_rec.person_type_action,
                                         g_employee_number
                                        );

                  IF g_person_type_id = gc_error_code_no_data_found
                  THEN
                     g_error_column_value :=
                          g_error_column_value || ',' || 'person_type_action';
                     g_error_msg := g_error_msg || ', ' || l_error_msg_005;
                     g_record_valid := gc_return_false_b;
                     xxccms_logging_util.log_audit_msg
                        (p_transaction_request_id      => g_transaction_request_id,
                         p_component_type              => xxccms_logging_util.c_comp_type_conc,
                         p_transaction_name            => 'MOD014 - DT020-24 Employee Synchronisation SMS to CCMS',
                         p_source_system               => xxccms_logging_util.c_message_type_sms,
                         p_source_name                 => xxccms_logging_util.c_message_type_sms,
                         p_target_system               => xxccms_logging_util.c_message_type_ebs,
                         p_target_name                 => xxccms_logging_util.c_message_type_ccms,
                         p_message_source_type         => xxccms_logging_util.c_message_type_plsql,
                         p_process_name                => 'xxccms_employeesync_pkg.main',
                         p_process_stage               => xxccms_logging_util.c_message_type_intermediate,
                         p_log_type                    => xxccms_logging_util.c_message_type_error,
                         p_record_ref_key              => 'Employee Number',
                         p_record_ref_value            => validate_rec.employee_number,
                         p_message_code                => '21',
                         p_message_description         => l_error_msg_005,
                         p_send_email                  => 'N',
                         p_email_id                    => NULL,
                         p_time_stamp                  => SYSDATE,
                         p_user_name                   => g_created_by,
                         p_status                      => l_status_err
                        );
                  ELSIF g_person_type_id = gc_error_code_others
                  THEN
                     g_error_column_value :=
                          g_error_column_value || ',' || 'person_type_action';
                     g_error_msg := g_error_msg || ', ' || SQLERRM;
                     g_record_valid := gc_return_false_b;
                     xxccms_logging_util.log_audit_msg
                        (p_transaction_request_id      => g_transaction_request_id,
                         p_component_type              => xxccms_logging_util.c_comp_type_conc,
                         p_transaction_name            => 'MOD014 - DT020-24 Employee Synchronisation SMS to CCMS',
                         p_source_system               => xxccms_logging_util.c_message_type_sms,
                         p_source_name                 => xxccms_logging_util.c_message_type_sms,
                         p_target_system               => xxccms_logging_util.c_message_type_ebs,
                         p_target_name                 => xxccms_logging_util.c_message_type_ccms,
                         p_message_source_type         => xxccms_logging_util.c_message_type_plsql,
                         p_process_name                => 'xxccms_employeesync_pkg.main',
                         p_process_stage               => xxccms_logging_util.c_message_type_intermediate,
                         p_log_type                    => xxccms_logging_util.c_message_type_warning,
                         p_record_ref_key              => 'Employee Number',
                         p_record_ref_value            => validate_rec.employee_number,
                         p_message_code                => '22',
                         p_message_description         =>    'Unknown Error occured while fetching Person type action'
                                                          || SUBSTR (SQLERRM,
                                                                     1,
                                                                     100
                                                                    ),
                         p_send_email                  => 'N',
                         p_email_id                    => NULL,
                         p_time_stamp                  => SYSDATE,
                         p_user_name                   => g_created_by,
                         p_status                      => l_status_err
                        );
                  END IF;
               ELSE
                  g_error_column_value :=
                          g_error_column_value || ',' || 'person_type_action';
                  g_error_msg := g_error_msg || ', ' || l_error_msg_004;
                  g_record_valid := gc_return_false_b;
                  xxccms_logging_util.log_audit_msg
                     (p_transaction_request_id      => g_transaction_request_id,
                      p_component_type              => xxccms_logging_util.c_comp_type_conc,
                      p_transaction_name            => 'MOD014 - DT020-24 Employee Synchronisation SMS to CCMS',
                      p_source_system               => xxccms_logging_util.c_message_type_sms,
                      p_source_name                 => xxccms_logging_util.c_message_type_sms,
                      p_target_system               => xxccms_logging_util.c_message_type_ebs,
                      p_target_name                 => xxccms_logging_util.c_message_type_ccms,
                      p_message_source_type         => xxccms_logging_util.c_message_type_plsql,
                      p_process_name                => 'xxccms_employeesync_pkg.main',
                      p_process_stage               => xxccms_logging_util.c_message_type_intermediate,
                      p_log_type                    => xxccms_logging_util.c_message_type_error,
                      p_record_ref_key              => 'Employee Number',
                      p_record_ref_value            => validate_rec.employee_number,
                      p_message_code                => '23',
                      p_message_description         => l_error_msg_004,
                      p_send_email                  => 'N',
                      p_email_id                    => NULL,
                      p_time_stamp                  => SYSDATE,
                      p_user_name                   => g_created_by,
                      p_status                      => l_status_err
                     );
               END IF;

              ---------------------------------------------------------------------------------
              --V08. Validation for field TITLE
              --   to validate the code coming in data file as against code in system
              ---------------------------------------------------------------------------------
               IF validate_rec.title IS NOT NULL
               THEN
                  val_lookup_code (gc_title_lookup,
                                   validate_rec.title,
                                   g_effective_date,
                                   g_employee_number,
                                   g_title,
                                   l_error_code
                                  );
               ELSE
                  g_title := NULL;
               END IF;

---------------------------------------------------------------------------------
--V08. Validation for mandatory field LAST_NAME
---------------------------------------------------------------------------------
               g_linecount := g_linecount + 1;

               IF validate_rec.last_name IS NULL
               THEN
                  g_error_column_value :=
                                   g_error_column_value || ',' || 'LAST_NAME';
                  g_error_msg := g_error_msg || ', ' || l_error_msg_006;
                  g_record_valid := gc_return_false_b;
                  xxccms_logging_util.log_audit_msg
                     (p_transaction_request_id      => g_transaction_request_id,
                      p_component_type              => xxccms_logging_util.c_comp_type_conc,
                      p_transaction_name            => 'MOD014 - DT020-24 Employee Synchronisation SMS to CCMS',
                      p_source_system               => xxccms_logging_util.c_message_type_sms,
                      p_source_name                 => xxccms_logging_util.c_message_type_sms,
                      p_target_system               => xxccms_logging_util.c_message_type_ebs,
                      p_target_name                 => xxccms_logging_util.c_message_type_ccms,
                      p_message_source_type         => xxccms_logging_util.c_message_type_plsql,
                      p_process_name                => 'xxccms_employeesync_pkg.main',
                      p_process_stage               => xxccms_logging_util.c_message_type_intermediate,
                      p_log_type                    => xxccms_logging_util.c_message_type_error,
                      p_record_ref_key              => 'Employee Number',
                      p_record_ref_value            => validate_rec.employee_number,
                      p_message_code                => '26',
                      p_message_description         => l_error_msg_006,
                      p_send_email                  => 'N',
                      p_email_id                    => NULL,
                      p_time_stamp                  => SYSDATE,
                      p_user_name                   => g_created_by,
                      p_status                      => l_status_err
                     );
               ELSE
                  g_last_name := validate_rec.last_name;
               END IF;

---------------------------------------------------------------------------------
--V09. assign FIRST_NAME to variable.
---------------------------------------------------------------------------------
               g_first_name := validate_rec.first_name;
---------------------------------------------------------------------------------
--V10. Validation for mandatory field GENDER
---------------------------------------------------------------------------------
               l_error_code := NULL;
               g_linecount := g_linecount + 1;
               g_bookmark := 'Calling Gender Validation Procedure';
               g_procedure_name := 'val_lookup_code';

               IF validate_rec.gender IS NOT NULL
               THEN
                  val_lookup_code (gc_sex_lookup,
                                   validate_rec.gender,
                                   g_effective_date,
                                   g_employee_number,
                                   g_gender,
                                   l_error_code
                                  );

                  IF l_error_code = gc_error_code_no_data_found
                  THEN
                     g_error_column_value :=
                                      g_error_column_value || ',' || 'GENDER';
                     g_error_msg := g_error_msg || ', ' || l_error_msg_008;
                     g_record_valid := gc_return_false_b;
                     xxccms_logging_util.log_audit_msg
                        (p_transaction_request_id      => g_transaction_request_id,
                         p_component_type              => xxccms_logging_util.c_comp_type_conc,
                         p_transaction_name            => 'MOD014 - DT020-24 Employee Synchronisation SMS to CCMS',
                         p_source_system               => xxccms_logging_util.c_message_type_sms,
                         p_source_name                 => xxccms_logging_util.c_message_type_sms,
                         p_target_system               => xxccms_logging_util.c_message_type_ebs,
                         p_target_name                 => xxccms_logging_util.c_message_type_ccms,
                         p_message_source_type         => xxccms_logging_util.c_message_type_plsql,
                         p_process_name                => 'xxccms_employeesync_pkg.main',
                         p_process_stage               => xxccms_logging_util.c_message_type_intermediate,
                         p_log_type                    => xxccms_logging_util.c_message_type_error,
                         p_record_ref_key              => 'Employee Number',
                         p_record_ref_value            => validate_rec.employee_number,
                         p_message_code                => '27',
                         p_message_description         => l_error_msg_008,
                         p_send_email                  => 'N',
                         p_email_id                    => NULL,
                         p_time_stamp                  => SYSDATE,
                         p_user_name                   => g_created_by,
                         p_status                      => l_status_err
                        );
                  ELSIF l_error_code = gc_error_code_others
                  THEN
                     g_error_column_value :=
                                      g_error_column_value || ',' || 'GENDER';
                     g_error_msg := g_error_msg || ', ' || SQLERRM;
                     g_record_valid := gc_return_false_b;
                     xxccms_logging_util.log_audit_msg
                        (p_transaction_request_id      => g_transaction_request_id,
                         p_component_type              => xxccms_logging_util.c_comp_type_conc,
                         p_transaction_name            => 'MOD014 - DT020-24 Employee Synchronisation SMS to CCMS',
                         p_source_system               => xxccms_logging_util.c_message_type_sms,
                         p_source_name                 => xxccms_logging_util.c_message_type_sms,
                         p_target_system               => xxccms_logging_util.c_message_type_ebs,
                         p_target_name                 => xxccms_logging_util.c_message_type_ccms,
                         p_message_source_type         => xxccms_logging_util.c_message_type_plsql,
                         p_process_name                => 'xxccms_employeesync_pkg.main',
                         p_process_stage               => xxccms_logging_util.c_message_type_intermediate,
                         p_log_type                    => xxccms_logging_util.c_message_type_error,
                         p_record_ref_key              => 'Employee Number',
                         p_record_ref_value            => validate_rec.employee_number,
                         p_message_code                => '28',
                         p_message_description         => 'Gender value not found in the Lookups',
                         p_send_email                  => 'N',
                         p_email_id                    => NULL,
                         p_time_stamp                  => SYSDATE,
                         p_user_name                   => g_created_by,
                         p_status                      => l_status_err
                        );
                  END IF;
               -- Updated on 14th Sep 2011 By Makarandsingh Sisodiya as per artifact number artf1563386
               -- Else Case removed as the Gender Column cannot be NULL
               END IF;

---------------------------------------------------------------------------------
--V11. Validation for field DOB
---------------------------------------------------------------------------------
               g_linecount := g_linecount + 1;

               IF validate_rec.dob IS NOT NULL
               THEN
                  IF validate_rec.dob > validate_rec.latest_start_date
                  THEN
                     g_error_column_value :=
                                         g_error_column_value || ',' || 'DOB';
                     g_error_msg := g_error_msg || ', ' || l_error_msg_009;
                     g_record_valid := gc_return_false_b;
                     xxccms_logging_util.log_audit_msg
                        (p_transaction_request_id      => g_transaction_request_id,
                         p_component_type              => xxccms_logging_util.c_comp_type_conc,
                         p_transaction_name            => 'MOD014 - DT020-24 Employee Synchronisation SMS to CCMS',
                         p_source_system               => xxccms_logging_util.c_message_type_sms,
                         p_source_name                 => xxccms_logging_util.c_message_type_sms,
                         p_target_system               => xxccms_logging_util.c_message_type_ebs,
                         p_target_name                 => xxccms_logging_util.c_message_type_ccms,
                         p_message_source_type         => xxccms_logging_util.c_message_type_plsql,
                         p_process_name                => 'xxccms_employeesync_pkg.main',
                         p_process_stage               => xxccms_logging_util.c_message_type_intermediate,
                         p_log_type                    => xxccms_logging_util.c_message_type_error,
                         p_record_ref_key              => 'Employee Number',
                         p_record_ref_value            => validate_rec.employee_number,
                         p_message_code                => '30',
                         p_message_description         => l_error_msg_009,
                         p_send_email                  => 'N',
                         p_email_id                    => NULL,
                         p_time_stamp                  => SYSDATE,
                         p_user_name                   => g_created_by,
                         p_status                      => l_status_err
                        );
                  END IF;
               ELSE
                  g_dob := validate_rec.dob;
               END IF;


               ---------------------------------------------------------------------------------
               --V13. Validate field location
               ---------------------------------------------------------------------------------
               g_linecount := g_linecount + 1;
               g_bookmark := 'Calling location Validation function';
               g_procedure_name := 'get_location_id';


--------------------------------------------------------------------------------------
--V14. Supervisor validation
--------------------------------------------------------------------------------------

               -- Updated On 20th Sep 2011 by Makarandsingh Sisodiya as per issues raised in artifact number artf1579423
               -- Updated Error logging message type from error to warning
               g_linecount := g_linecount + 1;
               g_bookmark := 'Calling supervisor Validation function';
               g_procedure_name := 'get_supervisor_id';
               -- UDit Shukla Start Supervisor validation  
              -- UDit Shukla End Supervisor validation 
               ---------------------------------------------------------------------------------
               --V15. Validation for retrieving ASSIGNMENT_NUMBER
               ---------------------------------------------------------------------------------

               -- Assigning the effective_date to actual termination date
               -- For assignment validation for reverse terminating person.

               -- End of assigning of effective date
               g_linecount := g_linecount + 1;
               g_bookmark := 'Calling assignment_number Validation Procedure';
               g_procedure_name := 'get_assignment_id';
               g_assignment_number := validate_rec.assignment_number;
               g_assign_num_error := NULL;

               ---------------------------------------------------------------------------------
               --V16 Validation for retrieving supervisor_assignment_id
               ---------------------------------------------------------------------------------
               g_linecount := g_linecount + 1;
               g_bookmark := 'Calling assignment_number Validation Procedure';
               g_procedure_name := 'get_super_assignment_id';
               g_assign_num_error := NULL;
               -- Getting Assignment Supervisor Id Udit Shukla 

              -- End Getting Assignment Supervisor Id Udit Shukla
-----------------------------------------------------------------------------------------
-- Getting object version number of employee
-----------------------------------------------------------------------------------------
               IF g_person_id IS NOT NULL AND g_emp_flag = 'Y'
               THEN
                  get_emp_object_version_number
                                              (g_person_id,
                                               g_employee_number,
                                               g_emp_date_start,
                                               g_per_service_id,
                                               g_emp_object_version_number,
                                               g_actual_termination_date_emp,
                                               l_error_code
                                              );

                  IF l_error_code = gc_error_code_no_data_found
                  THEN
                     g_error_column_value :=
                           g_error_column_value
                        || ','
                        || 'EMP_OBJECT_VERSION_NUMBER';
                     g_error_msg := g_error_msg || ', ' || l_error_msg_017;
                     g_record_valid := gc_return_false_b;
                     g_emp_object_version_number := NULL;
                     xxccms_logging_util.log_audit_msg
                        (p_transaction_request_id      => g_transaction_request_id,
                         p_component_type              => xxccms_logging_util.c_comp_type_conc,
                         p_transaction_name            => 'MOD014 - DT020-24 Employee Synchronisation SMS to CCMS',
                         p_source_system               => xxccms_logging_util.c_message_type_sms,
                         p_source_name                 => xxccms_logging_util.c_message_type_sms,
                         p_target_system               => xxccms_logging_util.c_message_type_ebs,
                         p_target_name                 => xxccms_logging_util.c_message_type_ccms,
                         p_message_source_type         => xxccms_logging_util.c_message_type_plsql,
                         p_process_name                => 'xxccms_employeesync_pkg.main',
                         p_process_stage               => xxccms_logging_util.c_message_type_intermediate,
                         p_log_type                    => xxccms_logging_util.c_message_type_error,
                         p_record_ref_key              => 'Employee Number',
                         p_record_ref_value            => validate_rec.employee_number,
                         p_message_code                => '55',
                         p_message_description         => l_error_msg_017,
                         p_send_email                  => 'N',
                         p_email_id                    => NULL,
                         p_time_stamp                  => SYSDATE,
                         p_user_name                   => g_created_by,
                         p_status                      => l_status_err
                        );
                  ELSIF l_error_code = gc_error_code_others
                  THEN
                     g_error_column_value :=
                           g_error_column_value
                        || ','
                        || 'EMP_OBJECT_VERSION_BUMER';
                     g_error_msg := g_error_msg || ', ' || SQLERRM;
                     g_record_valid := gc_return_false_b;
                     g_emp_object_version_number := NULL;
                     xxccms_logging_util.log_audit_msg
                        (p_transaction_request_id      => g_transaction_request_id,
                         p_component_type              => xxccms_logging_util.c_comp_type_conc,
                         p_transaction_name            => 'MOD014 - DT020-24 Employee Synchronisation SMS to CCMS',
                         p_source_system               => xxccms_logging_util.c_message_type_sms,
                         p_source_name                 => xxccms_logging_util.c_message_type_sms,
                         p_target_system               => xxccms_logging_util.c_message_type_ebs,
                         p_target_name                 => xxccms_logging_util.c_message_type_ccms,
                         p_message_source_type         => xxccms_logging_util.c_message_type_plsql,
                         p_process_name                => 'xxccms_employeesync_pkg.main',
                         p_process_stage               => xxccms_logging_util.c_message_type_intermediate,
                         p_log_type                    => xxccms_logging_util.c_message_type_error,
                         p_record_ref_key              => 'Employee Number',
                         p_record_ref_value            => validate_rec.employee_number,
                         p_message_code                => '56',
                         p_message_description         =>    'Unknowm Error occured while Object version number of employee,refer log for details'
                                                          || SUBSTR (SQLERRM,
                                                                     1,
                                                                     100
                                                                    ),
                         p_send_email                  => 'N',
                         p_email_id                    => NULL,
                         p_time_stamp                  => SYSDATE,
                         p_user_name                   => g_created_by,
                         p_status                      => l_status_err
                        );
                  END IF;
               END IF;

               IF l_db_status = 'N' AND l_status = 'Y'
               THEN
                  IF g_sys_per_type = 'EX_EMP'
                  THEN
                     g_effective_date := g_actual_termination_date_emp;
                  ELSE
                     g_effective_date := g_actual_termination_date_cwk;
                  END IF;
               END IF;
            ELSE
               g_linecount := g_linecount + 1;
               g_error_column_value :=
                              g_error_column_value || ',' || 'BUSINESS_GROUP';
               g_error_msg := g_error_msg || ', ' || l_error_msg_001;
               -- g_record_valid := gc_return_false_b;
               xxccms_logging_util.log_audit_msg
                  (p_transaction_request_id      => g_transaction_request_id,
                   p_component_type              => xxccms_logging_util.c_comp_type_conc,
                   p_transaction_name            => 'MOD014 - DT020-24 Employee Synchronisation SMS to CCMS',
                   p_source_system               => xxccms_logging_util.c_message_type_sms,
                   p_source_name                 => xxccms_logging_util.c_message_type_sms,
                   p_target_system               => xxccms_logging_util.c_message_type_ebs,
                   p_target_name                 => xxccms_logging_util.c_message_type_ccms,
                   p_message_source_type         => xxccms_logging_util.c_message_type_plsql,
                   p_process_name                => 'xxccms_employeesync_pkg.main',
                   p_process_stage               => xxccms_logging_util.c_message_type_intermediate,
                   p_log_type                    => xxccms_logging_util.c_message_type_error,
                   p_record_ref_key              => 'Employee Number',
                   p_record_ref_value            => validate_rec.employee_number,
                   p_message_code                => '57',
                   p_message_description         => l_error_msg_001,
                   p_send_email                  => 'N',
                   p_email_id                    => NULL,
                   p_time_stamp                  => SYSDATE,
                   p_user_name                   => g_created_by,
                   p_status                      => l_status_err
                  );
            END IF;                      -- closing business_group_id if loop.

------------------------------------------------------------------------------------------------
-- Resetting The effective_date to sysdate.
------------------------------------------------------------------------------------------------
            g_effective_date := TRUNC (SYSDATE);
---------------------------------------------------------------------------------
----------------
--         ELSIF l_status = 'Y' AND l_db_status = 'N' AND validate_rec.record_type = 'I'
--         THEN
--            NULL;

         ----------------
         ELSE
---------------------------------------------------------------------------------
--V17. getting object version number of employee
---------------------------------------------------------------------------------
            g_linecount := g_linecount + 1;
            g_bookmark :=
                 'Calling get_emp_object_version_number Validation Procedure';
            g_procedure_name := 'get_emp_object_version_number';
            g_effective_date := validate_rec.effective_end_date;

            IF g_person_id IS NOT NULL AND g_emp_flag = 'Y'
            THEN
               get_emp_object_version_number (g_person_id,
                                              g_employee_number,
                                              g_emp_date_start,
                                              g_per_service_id,
                                              g_emp_object_version_number,
                                              g_actual_termination_date_emp,
                                              l_error_code
                                             );

               IF l_error_code = gc_error_code_no_data_found
               THEN
                  g_error_column_value :=
                     g_error_column_value || ','
                     || 'EMP_OBJECT_VERSION_BUMER';
                  g_error_msg := g_error_msg || ', ' || l_error_msg_017;
                  g_record_valid := gc_return_false_b;
                  g_emp_object_version_number := NULL;
                  xxccms_logging_util.log_audit_msg
                     (p_transaction_request_id      => g_transaction_request_id,
                      p_component_type              => xxccms_logging_util.c_comp_type_conc,
                      p_transaction_name            => 'MOD014 - DT020-24 Employee Synchronisation SMS to CCMS',
                      p_source_system               => xxccms_logging_util.c_message_type_sms,
                      p_source_name                 => xxccms_logging_util.c_message_type_sms,
                      p_target_system               => xxccms_logging_util.c_message_type_ebs,
                      p_target_name                 => xxccms_logging_util.c_message_type_ccms,
                      p_message_source_type         => xxccms_logging_util.c_message_type_plsql,
                      p_process_name                => 'xxccms_employeesync_pkg.main',
                      p_process_stage               => xxccms_logging_util.c_message_type_intermediate,
                      p_log_type                    => xxccms_logging_util.c_message_type_error,
                      p_record_ref_key              => 'Employee Number',
                      p_record_ref_value            => validate_rec.employee_number,
                      p_message_code                => '58',
                      p_message_description         => l_error_msg_017,
                      p_send_email                  => 'N',
                      p_email_id                    => NULL,
                      p_time_stamp                  => SYSDATE,
                      p_user_name                   => g_created_by,
                      p_status                      => l_status_err
                     );
               ELSIF l_error_code = gc_error_code_others
               THEN
                  g_error_column_value :=
                     g_error_column_value || ','
                     || 'EMP_OBJECT_VERSION_BUMER';
                  g_error_msg := g_error_msg || ', ' || SQLERRM;
                  g_record_valid := gc_return_false_b;
                  g_emp_object_version_number := NULL;
                  xxccms_logging_util.log_audit_msg
                     (p_transaction_request_id      => g_transaction_request_id,
                      p_component_type              => xxccms_logging_util.c_comp_type_conc,
                      p_transaction_name            => 'MOD014 - DT020-24 Employee Synchronisation SMS to CCMS',
                      p_source_system               => xxccms_logging_util.c_message_type_sms,
                      p_source_name                 => xxccms_logging_util.c_message_type_sms,
                      p_target_system               => xxccms_logging_util.c_message_type_ebs,
                      p_target_name                 => xxccms_logging_util.c_message_type_ccms,
                      p_message_source_type         => xxccms_logging_util.c_message_type_plsql,
                      p_process_name                => 'xxccms_employeesync_pkg.main',
                      p_process_stage               => xxccms_logging_util.c_message_type_intermediate,
                      p_log_type                    => xxccms_logging_util.c_message_type_error,
                      p_record_ref_key              => 'Employee Number',
                      p_record_ref_value            => validate_rec.employee_number,
                      p_message_code                => '59',
                      p_message_description         =>    'Unknown error occured while getting object version number of employee,refer log for details'
                                                       || SUBSTR (SQLERRM,
                                                                  1,
                                                                  100
                                                                 ),
                      p_send_email                  => 'N',
                      p_email_id                    => NULL,
                      p_time_stamp                  => SYSDATE,
                      p_user_name                   => g_created_by,
                      p_status                      => l_status_err
                     );
               END IF;
            ELSIF g_person_id IS NULL
            THEN
               g_error_column_value :=
                    g_error_column_value || ',' || 'EMP_OBJECT_VERSION_BUMER';
               g_error_msg := g_error_msg || ', ' || l_error_msg_018;
               --g_record_valid                  := gc_return_false_b;
               g_emp_object_version_number := NULL;
               xxccms_logging_util.log_audit_msg
                  (p_transaction_request_id      => g_transaction_request_id,
                   p_component_type              => xxccms_logging_util.c_comp_type_conc,
                   p_transaction_name            => 'MOD014 - DT020-24 Employee Synchronisation SMS to CCMS',
                   p_source_system               => xxccms_logging_util.c_message_type_sms,
                   p_source_name                 => xxccms_logging_util.c_message_type_sms,
                   p_target_system               => xxccms_logging_util.c_message_type_ebs,
                   p_target_name                 => xxccms_logging_util.c_message_type_ccms,
                   p_message_source_type         => xxccms_logging_util.c_message_type_plsql,
                   p_process_name                => 'xxccms_employeesync_pkg.main',
                   p_process_stage               => xxccms_logging_util.c_message_type_intermediate,
                   p_log_type                    => xxccms_logging_util.c_message_type_error,
                   p_record_ref_key              => 'Employee Number',
                   p_record_ref_value            => validate_rec.employee_number,
                   p_message_code                => '60',
                   p_message_description         => l_error_msg_018,
                   p_send_email                  => 'N',
                   p_email_id                    => NULL,
                   p_time_stamp                  => SYSDATE,
                   p_user_name                   => g_created_by,
                   p_status                      => l_status_err
                  );
            END IF;
         END IF;

-- end of IF (Condition for elemination validations for insertion and updation)

         ------------------------------------------------------------------------------------------------
--If all validations pass then,
--call the API's to insert or update data into
--the base table PER_ALL_PEOPLE_F and PER_ASSIGNMENTS
------------------------------------------------------------------------------------------------
         g_linecount := g_linecount + 1;
         g_bookmark := 'Calling APIs from procedure  main';
         g_procedure_name := 'employee_main';

        --
        -- Calling procedures for employee creation,updation,termination and reverse termination
        --
         IF g_record_valid = gc_return_true_b
         THEN
            IF l_status = 'Y' AND l_db_status = 'Y'
            THEN
               IF validate_rec.record_type = 'I'
               THEN
                  create_employee;

                  IF (    g_person_id IS NOT NULL
                      AND validate_rec.supervisor IS NOT NULL
                     )
                  THEN
                      NULL;
                     --update_employee_asg; Udit Shukla
                  END IF;
               ELSIF validate_rec.record_type = 'N'
               THEN
                  IF validate_rec.person_update = 'Y'
                  THEN
                     update_person;
                  END IF;

                  IF validate_rec.assignment_update = 'Y'
                  THEN
                      NULL;
                     --update_employee_asg; Udit Shukla
                  END IF;
               END IF;
            ELSIF l_status = 'N' AND l_db_status = 'Y'
            THEN
               terminate_employee;
            ELSIF l_status = 'Y' AND l_db_status = 'N'
            THEN
               IF validate_rec.record_type = 'I'
               THEN
                  rehire_employee (g_person_id,
                                   g_employee_number,
                                   validate_rec.effective_start_date
                                  );
                  get_assignment_id (g_person_id,
                                     g_business_group_id,
                                     g_effective_date,
                                     g_employee_number,
                                     g_assignment_number,
                                     g_assignment_id,
                                     g_ass_object_version_number,
                                     g_assign_num_error,
                                     g_ass_eff_start_date
                                    );

                  IF g_emp_flag = 'Y'
                  THEN
                     g_ass_obj_ver_number_emp := g_ass_object_version_number;
                  ELSE
                     g_ass_obj_ver_number_cwk := g_ass_object_version_number;
                  END IF;

                  IF g_assign_num_error = gc_error_code_no_data_found
                  THEN
                     g_error_column_value :=
                           g_error_column_value || ',' || 'ASSIGNMENT_NUMBER';
                     g_error_msg := g_error_msg || ', ' || l_error_msg_014;
                     g_record_valid := gc_return_false_b;
                     xxccms_logging_util.log_audit_msg
                        (p_transaction_request_id      => g_transaction_request_id,
                         p_component_type              => xxccms_logging_util.c_comp_type_conc,
                         p_transaction_name            => 'MOD014 - DT020-24 Employee Synchronisation SMS to CCMS',
                         p_source_system               => xxccms_logging_util.c_message_type_sms,
                         p_source_name                 => xxccms_logging_util.c_message_type_sms,
                         p_target_system               => xxccms_logging_util.c_message_type_ebs,
                         p_target_name                 => xxccms_logging_util.c_message_type_ccms,
                         p_message_source_type         => xxccms_logging_util.c_message_type_plsql,
                         p_process_name                => 'xxccms_employeesync_pkg.main',
                         p_process_stage               => xxccms_logging_util.c_message_type_intermediate,
                         p_log_type                    => xxccms_logging_util.c_message_type_error,
                         p_record_ref_key              => 'Employee Number',
                         p_record_ref_value            => validate_rec.employee_number,
                         p_message_code                => '66',
                         p_message_description         => l_error_msg_014,
                         p_send_email                  => 'N',
                         p_email_id                    => NULL,
                         p_time_stamp                  => SYSDATE,
                         p_user_name                   => g_created_by,
                         p_status                      => l_status_err
                        );
                  ELSIF g_assign_num_error = gc_error_code_others
                  THEN
                     g_error_column_value :=
                           g_error_column_value || ',' || 'ASSIGNMENT_NUMBER';
                     g_error_msg := g_error_msg || ', ' || SQLERRM;
                     g_record_valid := gc_return_false_b;
                     xxccms_logging_util.log_audit_msg
                        (p_transaction_request_id      => g_transaction_request_id,
                         p_component_type              => xxccms_logging_util.c_comp_type_conc,
                         p_transaction_name            => 'MOD014 - DT020-24 Employee Synchronisation SMS to CCMS',
                         p_source_system               => xxccms_logging_util.c_message_type_sms,
                         p_source_name                 => xxccms_logging_util.c_message_type_sms,
                         p_target_system               => xxccms_logging_util.c_message_type_ebs,
                         p_target_name                 => xxccms_logging_util.c_message_type_ccms,
                         p_message_source_type         => xxccms_logging_util.c_message_type_plsql,
                         p_process_name                => 'xxccms_employeesync_pkg.main',
                         p_process_stage               => xxccms_logging_util.c_message_type_intermediate,
                         p_log_type                    => xxccms_logging_util.c_message_type_error,
                         p_record_ref_key              => 'Employee Number',
                         p_record_ref_value            => validate_rec.employee_number,
                         p_message_code                => '67',
                         p_message_description         =>    'Unknown error occured while fetching assignment number,refer log for details'
                                                          || SUBSTR (SQLERRM,
                                                                     1,
                                                                     100
                                                                    ),
                         p_send_email                  => 'N',
                         p_email_id                    => NULL,
                         p_time_stamp                  => SYSDATE,
                         p_user_name                   => g_created_by,
                         p_status                      => l_status_err
                        );
                  END IF;

                  g_assignment_number := validate_rec.assignment_number;
                  NULL;
                  --update_employee_asg; --Udit Shukla
               ELSE
                  reverse_terminate_employee (g_person_id,
                                              g_employee_number,
                                              g_actual_termination_date_emp
                                             );
               END IF;
            END IF;
         END IF;

         ---------------------------------------------------------------------------------------------------------------
         -- Update the staging table XXCCMS_EMPLOYEE_STG as per the status of the record.
         ---------------------------------------------------------------------------------------------------------------
         g_linecount := g_linecount + 1;
         g_bookmark := 'Tieback the staging table';
         g_procedure_name := 'employee_main';

         IF g_record_valid AND g_success = 'Y'-- AND g_ass_success = 'Y'
         THEN
            g_rec_valid := g_rec_valid + 1;
            g_linecount := g_linecount + 1;
            xxccms_logging_util.log_audit_msg
               (p_transaction_request_id      => g_transaction_request_id,
                p_component_type              => xxccms_logging_util.c_comp_type_conc,
                p_transaction_name            => 'MOD014 - DT020-24 Employee Synchronisation SMS to CCMS',
                p_source_system               => xxccms_logging_util.c_message_type_sms,
                p_source_name                 => xxccms_logging_util.c_message_type_sms,
                p_target_system               => xxccms_logging_util.c_message_type_ebs,
                p_target_name                 => xxccms_logging_util.c_message_type_ccms,
                p_message_source_type         => xxccms_logging_util.c_message_type_plsql,
                p_process_name                => 'xxccms_employeesync_pkg.main',
                p_process_stage               => xxccms_logging_util.c_message_type_intermediate,
                p_log_type                    => xxccms_logging_util.c_message_type_info,
                p_record_ref_key              => 'Employee Number',
                p_record_ref_value            => validate_rec.employee_number,
                p_message_code                => '69',
                p_message_description         => 'Records Processed Successfully ',
                p_send_email                  => 'N',
                p_email_id                    => NULL,
                p_time_stamp                  => SYSDATE,
                p_user_name                   => g_created_by,
                p_status                      => l_status_err
               );

            -- Commented By Makarandsingh Sisodiya on 22-Sep-2011 as per artifact number artf1586535
            IF (validate_rec.location IS NULL AND validate_rec.supervisor IS NULL)
            THEN
                
                UPDATE xxccms_employee_stg
                   SET record_status = 'PROCESSED'
                 WHERE rowid = validate_rec.rowid;
            ELSE
                
                UPDATE xxccms_employee_stg
                   SET record_status = 'PARTIAL'
                WHERE rowid = validate_rec.rowid;
            END IF;                                       
         ELSE
            --  ROLLBACK TO SAVEPOINT stagging_err;
            g_rec_invalid := g_rec_invalid + 1;
            g_linecount := g_linecount + 1;
            xxccms_logging_util.log_audit_msg
               (p_transaction_request_id      => g_transaction_request_id,
                p_component_type              => xxccms_logging_util.c_comp_type_conc,
                p_transaction_name            => 'MOD014 - DT020-24 Employee Synchronisation SMS to CCMS',
                p_source_system               => xxccms_logging_util.c_message_type_sms,
                p_source_name                 => xxccms_logging_util.c_message_type_sms,
                p_target_system               => xxccms_logging_util.c_message_type_ebs,
                p_target_name                 => xxccms_logging_util.c_message_type_ccms,
                p_message_source_type         => xxccms_logging_util.c_message_type_plsql,
                p_process_name                => 'xxccms_employeesync_pkg.main',
                p_process_stage               => xxccms_logging_util.c_message_type_intermediate,
                p_log_type                    => xxccms_logging_util.c_message_type_info,
                p_record_ref_key              => 'Employee Number',
                p_record_ref_value            => validate_rec.employee_number,
                p_message_code                => '70',
                p_message_description         => 'Records Processed with Error',
                p_send_email                  => 'N',
                p_email_id                    => NULL,
                p_time_stamp                  => SYSDATE,
                p_user_name                   => g_created_by,
                p_status                      => l_status_err
               );
            --l_err_count := l_err_count + 1;

            -- Commented By Makarandsingh Sisodiya on 22-Sep-2011 as per artifact number artf1586535
            
            UPDATE xxccms_employee_stg
               SET record_status = 'ERROR'
             WHERE rowid = validate_rec.rowid;
         END IF;

         g_emp_flag := 'N';
         l_status := NULL;
         l_db_status := NULL;
         g_success := 'N';
         g_new_emp_cwk_flag := 'N';
         g_ass_success := 'Y';
         COMMIT;
      END LOOP;
      -- Process assignments 
      process_partial_recs; 
    /*This will check whether there is error in processing the records into stagging table
      and throught error to concurrent program */
      IF g_rec_valid = 0
      THEN
         l_retcode := 0;
         l_errbuf := 'No Records Interfaced';
         xxccms_logging_util.log_audit_msg
            (p_transaction_request_id      => g_transaction_request_id,
             p_component_type              => xxccms_logging_util.c_comp_type_conc,
             p_transaction_name            => 'MOD014 - DT020-24 Employee Synchronisation SMS to CCMS',
             p_source_system               => xxccms_logging_util.c_message_type_sms,
             p_source_name                 => xxccms_logging_util.c_message_type_sms,
             p_target_system               => xxccms_logging_util.c_message_type_ebs,
             p_target_name                 => xxccms_logging_util.c_message_type_ccms,
             p_message_source_type         => xxccms_logging_util.c_message_type_plsql,
             p_process_name                => 'xxccms_employeesync_pkg.main',
             p_process_stage               => xxccms_logging_util.c_message_type_end,
             p_log_type                    => xxccms_logging_util.c_message_type_info,
             p_record_ref_key              => ' - Request Id - ',
             p_record_ref_value            => g_transaction_request_id,
             p_message_code                => '71',
             p_message_description         => 'No Records Interfaced',
             p_send_email                  => 'N',
             p_email_id                    => NULL,
             p_time_stamp                  => SYSDATE,
             p_user_name                   => g_created_by,
             p_status                      => l_status_err
            );
         xxccms_logging_util.update_audit_status
                    (p_component_type              => xxccms_logging_util.c_comp_type_conc,
                     p_transaction_request_id      => g_transaction_request_id,
                     p_status                      => xxccms_logging_util.c_message_type_error
                    );
      ELSIF g_rec_valid > 0 AND g_rec_invalid > 0
      THEN
         -- Updated Retcode value to 0 by Makarandsingh Sisodiya 
         l_retcode := 0;
         l_errbuf := 'Records Interfaced Partially';
         xxccms_logging_util.log_audit_msg
            (p_transaction_request_id      => g_transaction_request_id,
             p_component_type              => xxccms_logging_util.c_comp_type_conc,
             p_transaction_name            => 'MOD014 - DT020-24 Employee Synchronisation SMS to CCMS',
             p_source_system               => xxccms_logging_util.c_message_type_sms,
             p_source_name                 => xxccms_logging_util.c_message_type_sms,
             p_target_system               => xxccms_logging_util.c_message_type_ebs,
             p_target_name                 => xxccms_logging_util.c_message_type_ccms,
             p_message_source_type         => xxccms_logging_util.c_message_type_plsql,
             p_process_name                => 'xxccms_employeesync_pkg.main',
             p_process_stage               => xxccms_logging_util.c_message_type_end,
             p_log_type                    => xxccms_logging_util.c_message_type_warning,
             p_record_ref_key              => ' - Request Id - ',
             p_record_ref_value            => g_transaction_request_id,
             p_message_code                => '72',
             p_message_description         => 'Records Interfaced Partially',
             p_send_email                  => 'N',
             p_email_id                    => NULL,
             p_time_stamp                  => SYSDATE,
             p_user_name                   => g_created_by,
             p_status                      => l_status_err
            );
         xxccms_logging_util.update_audit_status
                    (p_component_type              => xxccms_logging_util.c_comp_type_conc,
                     p_transaction_request_id      => g_transaction_request_id,
                     p_status                      => xxccms_logging_util.c_message_type_warning
                    );
      ELSIF g_rec_invalid = 0
      THEN
         l_retcode := 0;
         l_errbuf := 'All Records Interfaced Successfully';
         xxccms_logging_util.log_audit_msg
            (p_transaction_request_id      => g_transaction_request_id,
             p_component_type              => xxccms_logging_util.c_comp_type_conc,
             p_transaction_name            => 'MOD014 - DT020-24 Employee Synchronisation SMS to CCMS',
             p_source_system               => xxccms_logging_util.c_message_type_sms,
             p_source_name                 => xxccms_logging_util.c_message_type_sms,
             p_target_system               => xxccms_logging_util.c_message_type_ebs,
             p_target_name                 => xxccms_logging_util.c_message_type_ccms,
             p_message_source_type         => xxccms_logging_util.c_message_type_plsql,
             p_process_name                => 'xxccms_employeesync_pkg.main',
             p_process_stage               => xxccms_logging_util.c_message_type_end,
             p_log_type                    => xxccms_logging_util.c_message_type_info,
             p_record_ref_key              => ' - Request Id - ',
             p_record_ref_value            => g_transaction_request_id,
             p_message_code                => '73',
             p_message_description         => 'All Records Interfaced Successfully',
             p_send_email                  => 'N',
             p_email_id                    => NULL,
             p_time_stamp                  => SYSDATE,
             p_user_name                   => g_created_by,
             p_status                      => l_status_err
            );
         xxccms_logging_util.update_audit_status
                    (p_component_type              => xxccms_logging_util.c_comp_type_conc,
                     p_transaction_request_id      => g_transaction_request_id,
                     p_status                      => xxccms_logging_util.c_message_type_complete
                    );
      END IF;

--------------------------------------------------------------------------------
--Initializing out parameters.
--------------------------------------------------------------------------------
      x_errbuf := l_errbuf;
      x_retcode := l_retcode;
      COMMIT;
-------------------------------------------------------------------------------
----------------------------------------------------------------------
-- Inserting Messages for Report generation
----------------------------------------------------------------------
      xxccms_logging_util.log_audit_msg
         (p_transaction_request_id      => g_transaction_request_id,
          p_component_type              => xxccms_logging_util.c_comp_type_conc,
          p_transaction_name            => 'MOD014 - DT020-24 Employee Synchronisation SMS to CCMS',
          p_source_system               => xxccms_logging_util.c_message_type_sms,
          p_source_name                 => xxccms_logging_util.c_message_type_sms,
          p_target_system               => xxccms_logging_util.c_message_type_ebs,
          p_target_name                 => xxccms_logging_util.c_message_type_ccms,
          p_message_source_type         => xxccms_logging_util.c_message_type_plsql,
          p_process_name                => 'xxccms_employeesync_pkg.main',
          p_process_stage               => xxccms_logging_util.c_message_type_intermediate,
          p_log_type                    => xxccms_logging_util.c_message_type_logging,
          p_record_ref_key              => ' - Request Id - ',
          p_record_ref_value            => g_transaction_request_id,
          p_message_code                => '74',
          p_message_description         =>    'Total Employee Records Processed are : '
                                           || ' '
                                           || l_total_records,
          p_send_email                  => 'N',
          p_email_id                    => NULL,
          p_time_stamp                  => SYSDATE,
          p_user_name                   => g_created_by,
          p_status                      => l_status_err
         );
      xxccms_logging_util.log_audit_msg
         (p_transaction_request_id      => g_transaction_request_id,
          p_component_type              => xxccms_logging_util.c_comp_type_conc,
          p_transaction_name            => 'MOD014 - DT020-24 Employee Synchronisation SMS to CCMS',
          p_source_system               => xxccms_logging_util.c_message_type_sms,
          p_source_name                 => xxccms_logging_util.c_message_type_sms,
          p_target_system               => xxccms_logging_util.c_message_type_ebs,
          p_target_name                 => xxccms_logging_util.c_message_type_ccms,
          p_message_source_type         => xxccms_logging_util.c_message_type_plsql,
          p_process_name                => 'xxccms_employeesync_pkg.main',
          p_process_stage               => xxccms_logging_util.c_message_type_intermediate,
          p_log_type                    => xxccms_logging_util.c_message_type_logging,
          p_record_ref_key              => ' - Request Id - ',
          p_record_ref_value            => g_transaction_request_id,
          p_message_code                => '75',
          p_message_description         =>    'Total Employee Records Processed Successfully are : '
                                           || ' '
                                           || g_rec_valid,
          p_send_email                  => 'N',
          p_email_id                    => NULL,
          p_time_stamp                  => SYSDATE,
          p_user_name                   => g_created_by,
          p_status                      => l_status_err
         );
      xxccms_logging_util.log_audit_msg
         (p_transaction_request_id      => g_transaction_request_id,
          p_component_type              => xxccms_logging_util.c_comp_type_conc,
          p_transaction_name            => 'MOD014 - DT020-24 Employee Synchronisation SMS to CCMS',
          p_source_system               => xxccms_logging_util.c_message_type_sms,
          p_source_name                 => xxccms_logging_util.c_message_type_sms,
          p_target_system               => xxccms_logging_util.c_message_type_ebs,
          p_target_name                 => xxccms_logging_util.c_message_type_ccms,
          p_message_source_type         => xxccms_logging_util.c_message_type_plsql,
          p_process_name                => 'xxccms_employeesync_pkg.main',
          p_process_stage               => xxccms_logging_util.c_message_type_intermediate,
          p_log_type                    => xxccms_logging_util.c_message_type_logging,
          p_record_ref_key              => ' - Request Id - ',
          p_record_ref_value            => g_transaction_request_id,
          p_message_code                => '76',
          p_message_description         =>    'Total Employee Records Processed With Error are : '
                                           || ' '
                                           || g_rec_invalid,
          p_send_email                  => 'N',
          p_email_id                    => NULL,
          p_time_stamp                  => SYSDATE,
          p_user_name                   => g_created_by,
          p_status                      => l_status_err
         );
      xxccms_logging_util.log_audit_msg
         (p_transaction_request_id      => g_transaction_request_id,
          p_component_type              => xxccms_logging_util.c_comp_type_conc,
          p_transaction_name            => 'MOD014 - DT020-24 Employee Synchronisation SMS to CCMS',
          p_source_system               => xxccms_logging_util.c_message_type_sms,
          p_source_name                 => xxccms_logging_util.c_message_type_sms,
          p_target_system               => xxccms_logging_util.c_message_type_ebs,
          p_target_name                 => xxccms_logging_util.c_message_type_ccms,
          p_message_source_type         => xxccms_logging_util.c_message_type_plsql,
          p_process_name                => 'xxccms_employeesync_pkg.main',
          p_process_stage               => xxccms_logging_util.c_message_type_end,
          p_log_type                    => xxccms_logging_util.c_message_type_info,
          p_record_ref_key              => ' - Request Id - ',
          p_record_ref_value            => g_transaction_request_id,
          p_message_code                => '77',
          p_message_description         => ' End of Main Procedure ',
          p_send_email                  => 'N',
          p_email_id                    => NULL,
          p_time_stamp                  => SYSDATE,
          p_user_name                   => g_created_by,
          p_status                      => l_status_err
         );
      xxccms_logging_util.update_audit_status
                    (p_component_type              => xxccms_logging_util.c_comp_type_conc,
                     p_transaction_request_id      => g_transaction_request_id,
                     p_status                      => xxccms_logging_util.c_message_type_complete
                    );
----------------------------------------------------
-- Generating report
----------------------------------------------------
      xxccms_logging_util.generate_report (g_transaction_request_id, 'OUT');
   EXCEPTION
      WHEN OTHERS
      THEN
         xxccms_logging_util.log_audit_msg
            (p_transaction_request_id      => g_transaction_request_id,
             p_component_type              => xxccms_logging_util.c_comp_type_conc,
             p_transaction_name            => 'MOD014 - DT020-24 Employee Synchronisation SMS to CCMS',
             p_source_system               => xxccms_logging_util.c_message_type_sms,
             p_source_name                 => xxccms_logging_util.c_message_type_sms,
             p_target_system               => xxccms_logging_util.c_message_type_ebs,
             p_target_name                 => xxccms_logging_util.c_message_type_ccms,
             p_message_source_type         => xxccms_logging_util.c_message_type_plsql,
             p_process_name                => 'xxccms_employeesync_pkg.main',
             p_process_stage               => xxccms_logging_util.c_message_type_end,
             p_log_type                    => xxccms_logging_util.c_message_type_error,
             p_record_ref_key              => ' - Request Id - ',
             p_record_ref_value            => g_transaction_request_id,
             p_message_code                => '78',
             p_message_description         =>    'Unknown Error occured in main package body '
                                              || ' ,refer log for details '
                                              || SUBSTR (SQLERRM, 1, 300),
             p_send_email                  => 'N',
             p_email_id                    => NULL,
             p_time_stamp                  => SYSDATE,
             p_user_name                   => g_created_by,
             p_status                      => l_status_err
            );
         xxccms_logging_util.update_audit_status
                    (p_component_type              => xxccms_logging_util.c_comp_type_conc,
                     p_transaction_request_id      => g_transaction_request_id,
                     p_status                      => xxccms_logging_util.c_message_type_error
                    );
         ROLLBACK;
         l_errbuf := SQLERRM;
         l_retcode := 2;
         x_errbuf := l_errbuf;
         x_retcode := l_retcode;
----------------------------------------------------
-- Generating report
----------------------------------------------------
         xxccms_logging_util.generate_report (g_transaction_request_id, 'OUT');
   END main;
END xxccms_employeesync_pkg;
/

SHOW ERRORS;