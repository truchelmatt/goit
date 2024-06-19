with step1 as(
select pgp.user_id as user_id, 
pgp.game_name as game_name, 
pgp.payment_date as payment_date, 
pgp.revenue_amount_usd as revenue, 
pgpu.language as language, 
pgpu.age as age
from project.games_payments pgp 
join project.games_paid_users pgpu 
on pgp.user_id = pgpu.user_id
where pgp.revenue_amount_usd>0),
--
step2 as(
select user_id,
min(payment_date) as first_payment,
max(payment_date) as last_payment,
DATE_PART('year', AGE(MAX(payment_date), MIN(payment_date))) * 12 + DATE_PART('month', AGE(MAX(payment_date), MIN(payment_date))) AS lt
from project.games_payments pgp 
group by 1),
--
step3 as(
select step1.user_id,
step1.game_name,
step1.payment_date,
step1.revenue,
step1.language,
step1.age,
step2.first_payment,
step2.last_payment,
step2.lt 
from step1
join step2 on step1.user_id=step2.user_id),
--
step4 as(
select user_id,
round(avg(revenue_amount_usd),2) as avg_revenue
from project.games_payments pgp 
group by 1),
--
step5 as(
select step3.*, 
step3.lt*step4.avg_revenue as clv, 
date(date_trunc('month', payment_date))as payment_month
from step3
join step4 on step3.user_id=step4.user_id
order by user_id, payment_date),
--
step6 as(
select *,
LAG(revenue) over (partition by user_id order by payment_month) as previous_revenue
from step5)
--
select *,
case when revenue < previous_revenue then 'expansion_mrr'
		when revenue > previous_revenue then 'contraction_mrr'
		ELSE '0'
    END AS mrr_type
from step6