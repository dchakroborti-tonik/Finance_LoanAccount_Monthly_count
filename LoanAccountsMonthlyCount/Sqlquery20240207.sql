select distinct new_loan_type, loanAccountNumber, EXTRACT(DATE FROM disbursementDateTime) AS Booking_Dt, disbursedLoanAmount as Booked_Volume
from prj-prod-dataplatform.risk_credit_mis.loan_master_table
where
reloan_flag = 1
and
flagDisbursement = 1
and EXTRACT(DATE FROM disbursementDateTime)  = '2024-02-06'
;

select new_loan_type,loantype, count(distinct loanAccountNumber)cnt
from
(select distinct new_loan_type, loantype, loanAccountNumber, EXTRACT(DATE FROM disbursementDateTime) AS Booking_Dt, disbursedLoanAmount as Booked_Volume
from prj-prod-dataplatform.risk_credit_mis.loan_master_table
where
reloan_flag = 1
and
flagDisbursement = 1
and EXTRACT(DATE FROM disbursementDateTime)  = '2024-02-06'
)
group by 1,2 order by 3 desc;

select new_loan_type, loantype, reloan_flag, count(distinct loanAccountNumber) cnt from 
(
select distinct new_loan_type, loantype, loanAccountNumber, EXTRACT(DATE FROM disbursementDateTime) AS Booking_Dt,DATE_TRUNC( termsAndConditionsSubmitDateTime,MONTH) submittedmonth, disbursedLoanAmount as Booked_Volume
,reloan_flag 
from prj-prod-dataplatform.risk_credit_mis.loan_master_table
where
loantype = 'FLEXUP' and new_loan_type = 'Flex-up'
and
flagDisbursement = 1
and EXTRACT(DATE FROM disbursementDateTime)  = '2024-02-06'
)
group by 1,2,3 order by 2 desc;


#Submitted loans found in flex-up

select * from 
(select distinct new_loan_type, loantype, loanAccountNumber, EXTRACT(DATE FROM disbursementDateTime) AS Booking_Dt,DATE_TRUNC(termsAndConditionsSubmitDateTime,MONTH) submittedmonth, disbursedLoanAmount as Booked_Volume
,reloan_flag 
from prj-prod-dataplatform.risk_credit_mis.loan_master_table
where
loantype = 'FLEXUP' and new_loan_type = 'Flex-up'
-- and
-- flagDisbursement = 1
)
where submittedmonth is not null
order by submittedmonth desc;

select distinct new_loan_type, loantype, digitalLoanAccountId, loanAccountNumber, reloan_flag, termsAndConditionsSubmitDateTime, flagDisbursement FROM 
    `prj-prod-dataplatform.risk_credit_mis.loan_master_table` where termsAndConditionsSubmitDateTime is not null  and new_loan_type = 'Flex-up'
    and  DATE_TRUNC(termsAndConditionsSubmitDateTime,MONTH) = '2024-02-01' and reloan_flag = 0
   ;

# loan applied
SELECT 
    DATE_TRUNC( startApplyDateTime,MONTH) as mm, 
    case when reloan_flag = 1  and loantype not like 'FLEXUP' then 'Reloan'
         when loantype = 'FLEXUP' and new_loan_type = 'Flex-up' and reloan_flag = 0 and flagDisbursement = 1 then 'Flex-up' 
         
         else new_loan_type end as LoanProduct,
    count (distinct digitalLoanAccountId) as StartedApps
FROM 
    `prj-prod-dataplatform.risk_credit_mis.loan_master_table` 

group by 1,2
order by 1 desc,2;


# loan Submitted
SELECT 
    DATE_TRUNC((case when loantype = 'FLEXUP' and new_loan_type = 'Flex-up' and reloan_flag = 0 and flagDisbursement = 1 then startApplyDateTime else termsAndConditionsSubmitDateTime end),MONTH) as mm,  
    case when reloan_flag = 1 and loantype not like 'FLEXUP'then 'Reloan'
         when loantype = 'FLEXUP' and new_loan_type = 'Flex-up' and reloan_flag = 0 and flagDisbursement = 1 then 'Flex-up' 
                  else new_loan_type end as LoanProduct,
    count (distinct digitalLoanAccountId) as SubmittedApps
FROM 
    `prj-prod-dataplatform.risk_credit_mis.loan_master_table` 
group by 1,2
order by 1 desc,2;

# Approved loans
SELECT 
DATE_TRUNC((case when loantype = 'FLEXUP' and new_loan_type = 'Flex-up' and reloan_flag = 0 and flagDisbursement = 1 then startApplyDateTime 
                  when reloan_flag = 1 and loantype not like 'FLEXUP' then startApplyDateTime else decision_date end),MONTH) as mm,
        case when reloan_flag = 1 and loantype not like 'FLEXUP'then 'Reloan'
         when loantype = 'FLEXUP' and new_loan_type = 'Flex-up' and reloan_flag = 0 and flagDisbursement = 1 then 'Flex-up' 
                  else new_loan_type end as LoanProduct,
    count (distinct digitalLoanAccountId) as ApprovedApps
FROM 
    `prj-prod-dataplatform.risk_credit_mis.loan_master_table`
where 
(case when loantype = 'FLEXUP' and new_loan_type = 'Flex-up' and reloan_flag = 0 and flagDisbursement = 1 then flagDisbursement 
      when reloan_flag = 1 and loantype not like 'FLEXUP' then flagDisbursement  else flagApproval end) = 1
group by 1,2
order by 1 desc,2
;

#Booked loans
SELECT 
DATE_TRUNC( disbursementDateTime,MONTH) as mm, 
            case when reloan_flag = 1 and loantype not like 'FLEXUP' and flagDisbursement = 1 then 'Reloan'
         when loantype = 'FLEXUP' and new_loan_type = 'Flex-up' and reloan_flag = 0 and flagDisbursement = 1 then 'Flex-up' 
                  else new_loan_type end as LoanProduct,
    count (distinct digitalLoanAccountId) as BookedApps
FROM 
    `prj-prod-dataplatform.risk_credit_mis.loan_master_table` 
    where flagDisbursement = 1

group by 1,2
order by 1 desc,2
;

# Booked Amount
SELECT 
DATE_TRUNC( disbursementDateTime,MONTH) as mm, 
    case when reloan_flag = 1 and loantype not like 'FLEXUP' and flagDisbursement = 1 then 'Reloan'
         when loantype = 'FLEXUP' and new_loan_type = 'Flex-up' and reloan_flag = 0 and flagDisbursement = 1 then 'Flex-up' 
                  else new_loan_type end as LoanProduct,
    sum (disbursedLoanAmount) as BookedAmt
FROM 
    `prj-prod-dataplatform.risk_credit_mis.loan_master_table` 
     where flagDisbursement = 1
group by 1,2
order by 1 desc,2
;

# Loan Tagging
SELECT
    loanAccountNumber,
    Case when reloan_flag = 1 and loantype not like 'FLEXUP' and flagDisbursement = 1 then 'Reloan'
         when loantype = 'FLEXUP' and new_loan_type = 'Flex-up' and reloan_flag = 0 and flagDisbursement = 1 then 'Flex-up' 
                  else new_loan_type end as LoanProduct,
    disbursementDateTime,
    (CASE WHEN new_loan_type = 'Flex-up' then
    LAG(new_loan_type) OVER (PARTITION BY customerId ORDER BY disbursementDateTime) END) AS OriginalLoanProduct
  FROM
    `prj-prod-dataplatform.risk_credit_mis.loan_master_table`
   where flagDisbursement=1
;

# Vas 

SELECT 
    extract(year from disbursementDateTime) as year , 
    extract(month from disbursementDateTime) as month,
    Case when reloan_flag = 1 and b.loantype not like 'FLEXUP' and flagDisbursement = 1 then 'Reloan'
         when b.loantype = 'FLEXUP' and new_loan_type = 'Flex-up' and reloan_flag = 0 and flagDisbursement = 1 then 'Flex-up' 
                  else new_loan_type end as new_loan_type, 
    count(distinct  b.loanAccountNumber ) AS TotalSold,
   
   count(distinct CASE WHEN vas_flag = 'true' THEN b.loanAccountNumber END) AS SoldWithVAS
     FROM `prj-prod-dataplatform.dl_loans_db_raw.tdbk_digital_loan_application` a join
`prj-prod-dataplatform.risk_credit_mis.loan_master_table` b on a.loanAccountNumber = b.loanAccountNumber
where flagDisbursement = 1
group by 1,2 ,3 
order by 1 desc,2 desc,3
;

select  date_trunc(startApplyDateTime, day),digitalLoanAccountId, loanAccountNumber, flagDisbursement, applicationStatus,termsAndConditionsSubmitDateTime, reloan_flag , new_loan_type, loanType
from `risk_credit_mis_uat.loan_master_table` where loantype = 'FLEXUP' and new_loan_type = 'Flex-up' and reloan_flag = 0
order by 1 desc ;