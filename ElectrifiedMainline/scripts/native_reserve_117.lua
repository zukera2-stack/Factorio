-- EM117: native reserve is fuel plus internal heat, never a new energy source.
local M={}
function M.parts(b)
  if not b then return 0,0,false end
  local f,h=b.remaining_burning_fuel or 0,b.heat or 0
  local ok=type(f)=='number' and type(h)=='number' and f==f and h==h
    and f>=0 and h>=0 and f<math.huge and h<math.huge and h<=b.heat_capacity+1e-5
  return f,h,ok
end
function M.total(e)
  if not (e and e.valid and e.burner) then return 0 end
  local f,h,ok=M.parts(e.burner)
  if not ok then error('[EM117] invalid native reserve') end
  return f+h
end
-- Upper bound on unknown reserve remaining and potentially unknown debit.
function M.debit(old,J,tick,max_debit)
  if not old or old.tick~=tick-1 or not old.trusted or J>old.J+1e-6 then
    return 0,J,0,false,"discontinuity"
  end
  local u=math.min(old.J,math.max(0,old.unknown or old.J))
  local d=math.max(0,old.J-J)
  -- Each own native burner has unit effectivity. Energy moving from fuel to
  -- heat is not a debit. The prototype API supplies the native per-tick cap.
  -- Never treat an impossible decrease as paid work or as proof of provenance.
  if type(max_debit)~='number' or max_debit~=max_debit or max_debit<=0 or max_debit==math.huge
    or d>max_debit+1e-4 then
    return 0,J,0,false,"debit-limit"
  end
  return d,math.min(u,J),math.min(u,d),true
end
return M
