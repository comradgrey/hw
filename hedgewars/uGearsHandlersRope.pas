(*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2012 Andrey Korotaev <unC0Rr@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 2 of the License
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA
 *)

{$INCLUDE "options.inc"}
unit uGearsHandlersRope;
interface

uses uTypes;

procedure doStepRope(Gear: PGear);

implementation
uses uConsts, uFloat, uCollisions, uVariables, uGearsList, uSound, uGearsUtils,
    uAmmos, uDebug, uUtils, uGearsHedgehog, uGearsRender;

procedure doStepRopeAfterAttack(Gear: PGear);
var 
    HHGear: PGear;
begin
    HHGear := Gear^.Hedgehog^.Gear;
    if ((HHGear^.State and gstHHDriven) = 0)
    or (CheckGearDrowning(HHGear))
    or (TestCollisionYwithGear(HHGear, 1) <> 0) then
        begin
        DeleteGear(Gear);
        isCursorVisible := false;
        ApplyAmmoChanges(HHGear^.Hedgehog^);
        exit
        end;

    HedgehogChAngle(HHGear);

    if TestCollisionXwithGear(HHGear, hwSign(HHGear^.dX)) then
        SetLittle(HHGear^.dX);

    if HHGear^.dY.isNegative and (TestCollisionYwithGear(HHGear, -1) <> 0) then
        HHGear^.dY := _0;
    HHGear^.X := HHGear^.X + HHGear^.dX;
    HHGear^.Y := HHGear^.Y + HHGear^.dY;
    HHGear^.dY := HHGear^.dY + cGravity;
    
    if (GameFlags and gfMoreWind) <> 0 then
        HHGear^.dX := HHGear^.dX + cWindSpeed / HHGear^.Density;

    if (Gear^.Message and gmAttack) <> 0 then
        begin
        Gear^.X := HHGear^.X;
        Gear^.Y := HHGear^.Y;

        ApplyAngleBounds(Gear^.Hedgehog^, amRope);

        Gear^.dX := SignAs(AngleSin(HHGear^.Angle), HHGear^.dX);
        Gear^.dY := -AngleCos(HHGear^.Angle);
        Gear^.Friction := _4_5 * cRopePercent;
        Gear^.Elasticity := _0;
        Gear^.State := Gear^.State and (not gsttmpflag);
        Gear^.doStep := @doStepRope;
        end
end;

procedure unstickHog(Gear, HHGear: PGear);
var i: LongInt;
    stuck: Boolean;
begin
    if (TestCollisionYwithGear(HHGear, 1) <> 0) and (TestCollisionYwithGear(HHGear, -1) = 0) then
        begin
        i:= 1;
        repeat
            begin
            inc(i);
            stuck:= TestCollisionYwithGear(HHGear, 1) <> 0;
            if stuck then HHGear^.Y:= HHGear^.Y-_1
            end
        until (i = 8) or (not stuck);
        HHGear^.Y:= HHGear^.Y+_1;
        // experiment in simulating something the shoppa players apparently expect
        if Gear^.Message and gmDown <> 0 then
            begin
            //HHGear^.dY:= HHGear^.dY / 16;
            //HHGear^.dY.QWordValue:= 0;
            HHGear^.dY:= -_0_1;
            HHGear^.dX:= HHGear^.dX * _1_5;
            end;
        if Gear^.Message and gmRight <> 0 then
            HHGear^.dX.isNegative:= false
        else if Gear^.Message and gmLeft <> 0 then
            HHGear^.dX.isNegative:= true
        end
    else if (TestCollisionYwithGear(HHGear, -1) <> 0) and (TestCollisionYwithGear(HHGear, 1) = 0) then
        begin
        i:= 1;
        repeat
            begin
            inc(i);
            stuck:= TestCollisionYwithGear(HHGear, -1) <> 0;
            if stuck then HHGear^.Y:= HHGear^.Y+_1
            end
        until (i = 8) or (not stuck);
        HHGear^.Y:= HHGear^.Y-_1;
        if Gear^.Message and gmDown <> 0 then
            begin
            //HHGear^.dY:= HHGear^.dY / 16;
            //HHGear^.dY.QWordValue:= 0;
            HHGear^.dY:= _0_1;
            HHGear^.dX:= HHGear^.dX * _1_5;
            end;
        if Gear^.Message and gmRight <> 0 then
            HHGear^.dX.isNegative:= true
        else if Gear^.Message and gmLeft <> 0 then
            HHGear^.dX.isNegative:= false
        end;
    if TestCollisionXwithGear(HHGear, 1) and (not TestCollisionXwithGear(HHGear, -1)) then
        begin
        i:= 1;
        repeat
            begin
            inc(i);
            stuck:= TestCollisionXwithGear(HHGear, 1);
            if stuck then HHGear^.X:= HHGear^.X-_1
            end
        until (i = 8) or (not stuck);
        HHGear^.X:= HHGear^.X+_1;
        if Gear^.Message and gmDown <> 0 then
            begin
            //HHGear^.dX:= HHGear^.dX / 16;
            //HHGear^.dX.QWordValue:= 0;
            HHGear^.dX:= -_0_1;
            HHGear^.dY:= HHGear^.dY * _1_5;
            end;
        if Gear^.Message and gmRight <> 0 then
            HHGear^.dY.isNegative:= true
        else if Gear^.Message and gmLeft <> 0 then
            HHGear^.dY.isNegative:= false
        end
    else if TestCollisionXwithGear(HHGear, -1) and (not TestCollisionXwithGear(HHGear, 1)) then
        begin
        i:= 1;
        repeat
            begin
            inc(i);
            stuck:= TestCollisionXwithGear(HHGear, -1);
            if stuck then HHGear^.X:= HHGear^.X+_1
            end
        until (i = 8) or (not stuck);
        HHGear^.X:= HHGear^.X-_1;
        if Gear^.Message and gmDown <> 0 then
            begin
            //HHGear^.dX:= HHGear^.dX / 16;
            //HHGear^.dX.QWordValue:= 0;
            HHGear^.dX:= _0_1;
            HHGear^.dY:= HHGear^.dY * _1_5;
            end;
        if Gear^.Message and gmRight <> 0 then
            HHGear^.dY.isNegative:= false
        else if Gear^.Message and gmLeft <> 0 then
            HHGear^.dY.isNegative:= true
        end
end;

procedure RopeDeleteMe(Gear, HHGear: PGear);
begin
    PlaySound(sndRopeRelease);
    HHGear^.dX.QWordValue:= HHGear^.dX.QWordValue div Gear^.stepFreq;
    HHGear^.dY.QWordValue:= HHGear^.dY.QWordValue div Gear^.stepFreq;
    with HHGear^ do
        begin
        Message := Message and (not gmAttack);
        State := (State or gstMoving) and (not gstWinner);
        end;
    unstickHog(Gear, HHGear);
    DeleteGear(Gear)
end;

procedure RopeWaitCollision(Gear, HHGear: PGear);
begin
    PlaySound(sndRopeRelease);
    with HHGear^ do
        begin
        Message := Message and (not gmAttack);
        State := State or gstMoving;
        end;
    unstickHog(Gear, HHGear);
    RopePoints.Count := 0;
    Gear^.Elasticity := _0;
    Gear^.doStep := @doStepRopeAfterAttack;
    HHGear^.dX.QWordValue:= HHGear^.dX.QWordValue div Gear^.stepFreq;
    HHGear^.dY.QWordValue:= HHGear^.dY.QWordValue div Gear^.stepFreq;
    Gear^.stepFreq := 1
end;

procedure doStepRopeWork(Gear: PGear);
var 
    HHGear: PGear;
    len, tx, ty, nx, ny, ropeDx, ropeDy, mdX, mdY, t: hwFloat;
    lx, ly, cd, i: LongInt;
    haveCollision,
    haveDivided: boolean;

begin
    if GameTicks mod 8 <> 0 then exit;

    HHGear := Gear^.Hedgehog^.Gear;
    haveCollision:= false;
    if (Gear^.Message and gmLeft  <> 0) and (not TestCollisionXwithGear(HHGear, -1)) then
        HHGear^.dX := HHGear^.dX - _0_0128
    else haveCollision:= true;

    if (Gear^.Message and gmRight <> 0) and (not TestCollisionXwithGear(HHGear,  1)) then
        HHGear^.dX := HHGear^.dX + _0_0128
    else haveCollision:= true;


    if ((HHGear^.State and gstHHDriven) = 0)
       or (CheckGearDrowning(HHGear)) or (Gear^.PortalCounter <> 0) then
        begin
        RopeDeleteMe(Gear, HHGear);
        exit
        end;

    // vector between hedgehog and rope attaching point
    ropeDx := HHGear^.X - Gear^.X;
    ropeDy := HHGear^.Y - Gear^.Y;

    if TestCollisionYwithGear(HHGear, 1) = 0 then
        begin

        // depending on the rope vector we know which X-side to check for collision
        // in order to find out if the hog can still be moved by gravity
        if ropeDx.isNegative = RopeDy.IsNegative then
            cd:= -1
        else
            cd:= 1;

        // apply gravity if there is no obstacle
        if not TestCollisionXwithGear(HHGear, cd) then
            HHGear^.dY := HHGear^.dY + cGravity * 64;

        if (GameFlags and gfMoreWind) <> 0 then
            // apply wind if there's no obstacle
            if not TestCollisionXwithGear(HHGear, hwSign(cWindSpeed)) then
                HHGear^.dX := HHGear^.dX + cWindSpeed * 64 / HHGear^.Density;
        end
    else haveCollision:= true;

    if ((Gear^.Message and gmDown) <> 0) and (Gear^.Elasticity < Gear^.Friction) then
        if not (TestCollisionXwithGear(HHGear, hwSign(ropeDx))
        or (TestCollisionYwithGear(HHGear, hwSign(ropeDy)) <> 0)) then
            Gear^.Elasticity := Gear^.Elasticity + _2_4
    else haveCollision:= true;

    if ((Gear^.Message and gmUp) <> 0) and (Gear^.Elasticity > _30) then
        if not (TestCollisionXwithGear(HHGear, -hwSign(ropeDx))
        or (TestCollisionYwithGear(HHGear, -hwSign(ropeDy)) <> 0)) then
            Gear^.Elasticity := Gear^.Elasticity - _2_4
    else haveCollision:= true;

(*
I am not so sure this is useful. Disabling
    if haveCollision then
        begin
        if TestCollisionXwithGear(HHGear, hwSign(HHGear^.dX)) and not TestCollisionXwithGear(HHGear, hwSign(HHGear^.dX)) then
            HHGear^.dX.isNegative:= not HHGear^.dX.isNegative;
        if (TestCollisionYwithGear(HHGear, hwSign(HHGear^.dY)) <> 0) and (TestCollisionYwithGear(HHGear, -hwSign(HHGear^.dY)) = 0) then
            HHGear^.dY.isNegative:= not HHGear^.dY.isNegative;
        end;
*)

    mdX := ropeDx + HHGear^.dX;
    mdY := ropeDy + HHGear^.dY;
    len := _1 / Distance(mdX, mdY);
    // rope vector plus hedgehog direction vector normalized
    mdX := mdX * len;
    mdY := mdY * len;

    // for visual purposes only
    Gear^.dX := mdX;
    Gear^.dY := mdY;

    /////
    tx := HHGear^.X;
    ty := HHGear^.Y;

    HHGear^.X := Gear^.X + mdX * Gear^.Elasticity;
    HHGear^.Y := Gear^.Y + mdY * Gear^.Elasticity;

    HHGear^.dX := HHGear^.X - tx;
    HHGear^.dY := HHGear^.Y - ty;
    ////


    haveDivided := false;
    // check whether rope needs dividing

    len := Gear^.Elasticity - _5;
    nx := Gear^.X + mdX * len;
    ny := Gear^.Y + mdY * len;
    tx := mdX * _2_4; // should be the same as increase step
    ty := mdY * _2_4;

    while len > _3 do
        begin
        lx := hwRound(nx);
        ly := hwRound(ny);
        if ((ly and LAND_HEIGHT_MASK) = 0) and ((lx and LAND_WIDTH_MASK) = 0) and ((Land[ly, lx] and $FF00) <> 0) then
            begin
            ny := _1 / Distance(ropeDx, ropeDy);
            // old rope pos
            nx := ropeDx * ny;
            ny := ropeDy * ny;

            with RopePoints.ar[RopePoints.Count] do
                begin
                X := Gear^.X;
                Y := Gear^.Y;
                if RopePoints.Count = 0 then
                    RopePoints.HookAngle := DxDy2Angle(Gear^.dY, Gear^.dX);
                b := (nx * HHGear^.dY) > (ny * HHGear^.dX);
                dLen := len
                end;
                
            with RopePoints.rounded[RopePoints.Count] do
                begin
                X := hwRound(Gear^.X);
                Y := hwRound(Gear^.Y);
                end;

            Gear^.X := Gear^.X + nx * len;
            Gear^.Y := Gear^.Y + ny * len;
            inc(RopePoints.Count);
            TryDo(RopePoints.Count <= MAXROPEPOINTS, 'Rope points overflow', true);
            Gear^.Elasticity := Gear^.Elasticity - len;
            Gear^.Friction := Gear^.Friction - len;
            haveDivided := true;
            break
            end;
        nx := nx - tx;
        ny := ny - ty;

        // len := len - _2_4 // should be the same as increase step
        len.QWordValue := len.QWordValue - _2_4.QWordValue;
        end;

    if not haveDivided then
        if RopePoints.Count > 0 then // check whether the last dividing point could be removed
            begin
            tx := RopePoints.ar[Pred(RopePoints.Count)].X;
            ty := RopePoints.ar[Pred(RopePoints.Count)].Y;
            mdX := tx - Gear^.X;
            mdY := ty - Gear^.Y;
            if RopePoints.ar[Pred(RopePoints.Count)].b xor (mdX * (ty - HHGear^.Y) > (tx - HHGear^.X) * mdY) then
                begin
                dec(RopePoints.Count);
                Gear^.X := RopePoints.ar[RopePoints.Count].X;
                Gear^.Y := RopePoints.ar[RopePoints.Count].Y;
                Gear^.Elasticity := Gear^.Elasticity + RopePoints.ar[RopePoints.Count].dLen;
                Gear^.Friction := Gear^.Friction + RopePoints.ar[RopePoints.Count].dLen;

                // restore hog position
                len := _1 / Distance(mdX, mdY);
                mdX := mdX * len;
                mdY := mdY * len;

                HHGear^.X := Gear^.X - mdX * Gear^.Elasticity;
                HHGear^.Y := Gear^.Y - mdY * Gear^.Elasticity;
                end
            end;

    haveCollision := false;
    if TestCollisionXwithGear(HHGear, hwSign(HHGear^.dX)) then
        begin
        HHGear^.dX := -_0_6 * HHGear^.dX;
        haveCollision := true
        end;
    if TestCollisionYwithGear(HHGear, hwSign(HHGear^.dY)) <> 0 then
        begin
        HHGear^.dY := -_0_6 * HHGear^.dY;
        haveCollision := true
        end;

    if haveCollision and (Gear^.Message and (gmLeft or gmRight) <> 0) and (Gear^.Message and (gmUp or gmDown) <> 0) then
        begin
        HHGear^.dX := SignAs(hwAbs(HHGear^.dX) + _1_6, HHGear^.dX);
        HHGear^.dY := SignAs(hwAbs(HHGear^.dY) + _1_6, HHGear^.dY)
        end;

    len := hwSqr(HHGear^.dX) + hwSqr(HHGear^.dY);
    if len > _49 then
        begin
        len := _7 / hwSqrt(len);
        HHGear^.dX := HHGear^.dX * len;
        HHGear^.dY := HHGear^.dY * len;
        end;

    haveCollision:= ((hwRound(Gear^.Y) and LAND_HEIGHT_MASK) = 0) and ((hwRound(Gear^.X) and LAND_WIDTH_MASK) = 0) and ((Land[hwRound(Gear^.Y), hwRound(Gear^.X)]) <> 0);

    if not haveCollision then
        begin
        // backup gear location
        tx:= Gear^.X;
        ty:= Gear^.Y;

        if RopePoints.Count > 0 then
            begin
            // set gear location to the remote end of the rope, the attachment point
            Gear^.X:= RopePoints.ar[0].X;
            Gear^.Y:= RopePoints.ar[0].Y;
            end;

        CheckCollision(Gear);
        // if we haven't found any collision yet then check the other side too
        if (Gear^.State and gstCollision) = 0 then
            begin
            Gear^.dX.isNegative:= not Gear^.dX.isNegative;
            Gear^.dY.isNegative:= not Gear^.dY.isNegative;
            CheckCollision(Gear);
            Gear^.dX.isNegative:= not Gear^.dX.isNegative;
            Gear^.dY.isNegative:= not Gear^.dY.isNegative;
            end;

        haveCollision:= (Gear^.State and gstCollision) <> 0;

        // restore gear location
        Gear^.X:= tx;
        Gear^.Y:= ty;
        end;

    // if the attack key is pressed, lose rope contact as well
    if (Gear^.Message and gmAttack) <> 0 then
        haveCollision:= false;

    if not haveCollision then
        begin
        if (Gear^.State and gsttmpFlag) <> 0 then
            begin
            if Gear^.Hedgehog^.CurAmmoType <> amParachute then
                RopeWaitCollision(Gear, HHGear)
            else
                RopeDeleteMe(Gear, HHGear)
            end
        end
    else
        if (Gear^.State and gsttmpFlag) = 0 then
            Gear^.State := Gear^.State or gsttmpFlag;
end;

procedure RopeRemoveFromAmmo(Gear, HHGear: PGear);
begin
    if (Gear^.State and gstAttacked) = 0 then
        begin
        OnUsedAmmo(HHGear^.Hedgehog^);
        Gear^.State := Gear^.State or gstAttacked
        end;
    ApplyAmmoChanges(HHGear^.Hedgehog^)
end;

procedure doStepRopeAttach(Gear: PGear);
var 
    HHGear: PGear;
    tx, ty, tt: hwFloat;
begin
    Gear^.X := Gear^.X - Gear^.dX;
    Gear^.Y := Gear^.Y - Gear^.dY;
    Gear^.Elasticity := Gear^.Elasticity + _1;

    HHGear := Gear^.Hedgehog^.Gear;
    DeleteCI(HHGear);

    if (HHGear^.State and gstMoving) <> 0 then
        begin
        if TestCollisionXwithGear(HHGear, hwSign(HHGear^.dX)) then
            SetLittle(HHGear^.dX);
        if HHGear^.dY.isNegative and (TestCollisionYwithGear(HHGear, -1) <> 0) then
            HHGear^.dY := _0;

        HHGear^.X := HHGear^.X + HHGear^.dX;
        Gear^.X := Gear^.X + HHGear^.dX;

        if TestCollisionYwithGear(HHGear, 1) <> 0 then
            begin
            CheckHHDamage(HHGear);
            HHGear^.dY := _0
            //HHGear^.State:= HHGear^.State and (not (gstHHJumping or gstHHHJump));
            end
        else
            begin
            HHGear^.Y := HHGear^.Y + HHGear^.dY;
            Gear^.Y := Gear^.Y + HHGear^.dY;
            HHGear^.dY := HHGear^.dY + cGravity;
            if (GameFlags and gfMoreWind) <> 0 then
                HHGear^.dX := HHGear^.dX + cWindSpeed / HHGear^.Density
            end;

        tt := Gear^.Elasticity;
        tx := _0;
        ty := _0;
        while tt > _20 do
            begin
            if ((hwRound(Gear^.Y+ty) and LAND_HEIGHT_MASK) = 0) and ((hwRound(Gear^.X+tx) and LAND_WIDTH_MASK) = 0) and ((Land[hwRound(Gear^.Y+ty), hwRound(Gear^.X+tx)] and $FF00) <> 0) then
                begin
                Gear^.X := Gear^.X + tx;
                Gear^.Y := Gear^.Y + ty;
                Gear^.Elasticity := tt;
                Gear^.doStep := @doStepRopeWork;
                Gear^.stepFreq:= 8;
                PlaySound(sndRopeAttach);
                with HHGear^ do
                    begin
                    dX.QWordValue:= dX.QWordValue shl 3;
                    dY.QWordValue:= dY.QWordValue shl 3;
                    State := State and (not (gstAttacking or gstHHJumping or gstHHHJump));
                    Message := Message and (not gmAttack)
                    end;

                RopeRemoveFromAmmo(Gear, HHGear);

                tt := _0;
                exit
                end;
            tx := tx + Gear^.dX + Gear^.dX;
            ty := ty + Gear^.dY + Gear^.dY;
            tt := tt - _2;
            end;
        end;

    if Gear^.Elasticity < _20 then Gear^.CollisionMask:= $FF00
    else Gear^.CollisionMask:= $FF7F;
    CheckCollision(Gear);

    if (Gear^.State and gstCollision) <> 0 then
        if Gear^.Elasticity < _10 then
            Gear^.Elasticity := _10000
    else
        begin
        Gear^.doStep := @doStepRopeWork;
        Gear^.stepFreq:= 8;
        PlaySound(sndRopeAttach);
        with HHGear^ do
            begin
            dX.QWordValue:= dX.QWordValue shl 3;
            dY.QWordValue:= dY.QWordValue shl 3;
            State := State and (not (gstAttacking or gstHHJumping or gstHHHJump));
            Message := Message and (not gmAttack)
            end;

        RopeRemoveFromAmmo(Gear, HHGear);

        exit
        end;

    if (Gear^.Elasticity > Gear^.Friction)
        or ((Gear^.Message and gmAttack) = 0)
        or ((HHGear^.State and gstHHDriven) = 0)
        or (HHGear^.Damage > 0) then
            begin
            with Gear^.Hedgehog^.Gear^ do
                begin
                State := State and (not gstAttacking);
                Message := Message and (not gmAttack)
                end;
        DeleteGear(Gear);
        exit;
        end;
    if CheckGearDrowning(HHGear) then DeleteGear(Gear)
end;

procedure doStepRope(Gear: PGear);
begin
    Gear^.dX := - Gear^.dX;
    Gear^.dY := - Gear^.dY;
    Gear^.doStep := @doStepRopeAttach;
    PlaySound(sndRopeShot)
end;

end.