using Godot;
using System;
using System.Collections.Generic;

namespace KritiKart;

/// <summary>
/// C# gameplay core for KritiKart: the drift-boost state machine and race
/// standings math, implemented in C# for deterministic, allocation-light
/// per-tick updates. GDScript systems may call the static helpers directly;
/// as a Node it also runs standalone (used by tests/cs probe scenes).
/// </summary>
public partial class KartGameplayCore : Node
{
    [Signal] public delegate void DriftBoostStartedEventHandler();
    [Signal] public delegate void DriftBoostEndedEventHandler();

    [Export] public float DriftBoostChargeTimeS = 0.7f;
    [Export] public float DriftBoostDurationS = 0.85f;

    private float _driftChargeS;
    private float _boostTimeRemainingS;
    private bool _wasDrifting;

    public float ChargeRatio =>
        DriftBoostChargeTimeS <= 0f ? 0f : Mathf.Clamp(_driftChargeS / DriftBoostChargeTimeS, 0f, 1f);

    public bool BoostActive => _boostTimeRemainingS > 0f;

    /// <summary>Advance the boost state machine by one tick.</summary>
    public void UpdateBoost(double delta, bool isDrifting)
    {
        float dt = (float)delta;
        bool driftJustEnded = _wasDrifting && !isDrifting;
        _wasDrifting = isDrifting;

        if (isDrifting)
        {
            _driftChargeS += dt;
        }
        else if (driftJustEnded)
        {
            if (_driftChargeS >= Mathf.Max(DriftBoostChargeTimeS, 0.01f))
            {
                _boostTimeRemainingS = Mathf.Max(DriftBoostDurationS, 0.05f);
                EmitSignal(SignalName.DriftBoostStarted);
            }
            _driftChargeS = 0f;
        }

        if (_boostTimeRemainingS > 0f)
        {
            _boostTimeRemainingS = Mathf.Max(0f, _boostTimeRemainingS - dt);
            if (_boostTimeRemainingS <= 0f)
                EmitSignal(SignalName.DriftBoostEnded);
        }
    }

    /// <summary>
    /// Rank racers by total race distance (lap * trackLength + lapDistance).
    /// Returns competitor indices ordered first-to-last. Ties keep input order.
    /// </summary>
    public static int[] RankByDistance(double[] totalDistancesM)
    {
        var order = new List<int>(totalDistancesM.Length);
        for (int i = 0; i < totalDistancesM.Length; i++) order.Add(i);
        order.Sort((a, b) =>
        {
            int byDistance = totalDistancesM[b].CompareTo(totalDistancesM[a]);
            return byDistance != 0 ? byDistance : a.CompareTo(b);
        });
        return order.ToArray();
    }

    /// <summary>1-based race position of a competitor given everyone's total distance.</summary>
    public static int PositionOf(int competitor, double[] totalDistancesM)
    {
        if (competitor < 0 || competitor >= totalDistancesM.Length) return -1;
        double mine = totalDistancesM[competitor];
        int position = 1;
        foreach (double d in totalDistancesM)
            if (d > mine) position++;
        return position;
    }

    /// <summary>Rubber-band factor: trailing racers get up to +maxCatchup, leaders -maxCatchup.</summary>
    public static float RubberBandFactor(int position, int racerCount, float maxCatchup)
    {
        if (racerCount <= 1 || position < 1) return 1f;
        float t = (position - 1) / (float)(racerCount - 1); // 0 = leader, 1 = last
        return 1f + Mathf.Lerp(-maxCatchup, maxCatchup, t);
    }
}
