select

distinct m.coreid,

-- grad year

m.coreprefyr,

-- donor (0/1)

case
when m.coreid in
(
select giftid from gifts
where
	(	
		(
			gifttype in 
				(
					'g','p','r'
				) 
			and 
			giftsolic <> 'lplate'
			and
			gifttender <> 'gik'
		)
		or 
		(
			gifttype = 'c'
			and
			giftsolic <> 'lplate'
			and
			gifttender <> 'gik'
			and  
			(
				giftplgkey = 0 
				or 
				giftplgkey is null
			)
		)
	)
)
then 1
else 0
end
as donor,

-- scholarship recipient (0/1)

case
when m.coreid in
(
select relid from relation
where
relisa = 'schstu'
)
then 1
else 0
end
as schlshp,

-- student group (0/inf)

case
when m.coreid in
(
select demoid from demogrph_full 
where
demotype = 'alfstu'
)
then
(
select top 1 demovalue from demogrph_full 
where
m.coreid = demoid
and
demotype = 'alfstu'
)
else 0
end
as stu_grp,

-- legacy status (parent attended) (0/1)

case
when m.coreid in
(
select demoid from demogrph_full 
where
demotype = 'alfleg'
)
then 1
else 0
end
as legacy,

-- event attendance (0/1)

case
when m.coreid in
(
select demoid from demogrph_full 
where
demotype = 'alfevn'
)
then 1
else 0
end
as evnt,

-- job status (0/1)

case
when m.coreid in
(
select jobsid from jobs
where
jobsstatus = 'act'
and
jobsstopdt is null
and 
(jobstitle is not null or jobsconame is not null)
)
then 1
else 0
end
as job,

-- student gov't involvement (0/1)

case
when coreid in
(
select attrid from attribute
where
attrtype in ('sg','su')
)
then 1
else 0
end
as st_gov,

-- phone-a-thon caller (0/1)

case
when coreid in
(
select attrid from attribute 
where
attrtype = 'phon'
)
then 1
else 0
end
as top_caller,

-- athlete (0/1)

case
when coreid in
(
select attrid from attribute 
where
attrgroup = 'sport'
)
then 1
else 0
end
as athlete,

-- greek involvement (0/1)

case
when coreid in
(
select attrid from attribute 
where
attrtype  in ('abc','ah','ak','akdel','akp','ao','aocecf','aocf','ap','aps','apso','as','asa','asp','ato',
'cd','detde','dsp','dsplx','dt','dups','dz','gl','gpb','gr','grgod','inter','intgc','iota','ipteo','ita',
'ka','kkp','odk','op','opp','pat','pbc','pbetas','pbsf','pctig','pek','pes','pgp','phimu','piaf','pk',
'pma','pmasin','pspc','pssf','rho','saii','sala','sgr','sk1','slb','slgns','slgsi','sp','spesbs','spfi',
'sss','std','tc','tk','tke','zd','zp','zpbsi','pn')
)
then 1
else 0
end
as greek,

-- volunteer status (0/1)

case
when m.coreid in
(
select cbioid from custombio
where
cbiolook3 in ('yes','conf')
and
cbiolook4 is not null
)
then 1
else 0
end
as volunteered,

-- survey response expressing desire to financially support the university (0/1)

case
when m.coreid in
(
select attrid from attribute
where
attrtype = 'grdfst'
and
attrtext = 'Financially support GVSU'
)
then 1
else 0
end
as fin_sup,

---- total giving and base ten log of total giving to help control extreme skewness
isnull (f.finamount,0) as ttl_gv,
isnull (LOG10(1 + f.finamount),0) as log_tg

from corebio m

left outer join demogrph_full 
on coreid = demoid

left outer join finance f
on m.coreid = f.finid
and f.finkey = isnull ((select top 1 finkey from finance_full sub
where sub.finid = f.finid
and (sub.fintype = 'donlif' or sub.fintype like 'ds%')
order by finamount desc), 0)

where

-- using birth years defined in Chronicle of Higher Ed survey defining Millennials (1980 - 2000)

m.corebrthyr >= 1980

and

m.corebrthyr <= 2000

and

m.corecfae = 'A'

and

m.coreid not in (select deathid from death)
