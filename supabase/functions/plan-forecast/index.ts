import { serve } from "std/http/server.ts";

type Req = {
  lat: number;
  lon: number;
  startDate: string;
  endDate: string;
};

type TideEvent = {
  time: string;
  type: string;
  height?: number;
};

serve(async (req: Request): Promise<Response> => {
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method Not Allowed" }), {
      status: 405,
      headers: { "Content-Type": "application/json" },
    });
  }

  let body: Req;
  try {
    body = (await req.json()) as Req;
  } catch {
    return new Response(JSON.stringify({ error: "Bad JSON" }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }

  const { lat, lon, startDate, endDate } = body;
  if (
    typeof lat !== "number" ||
    typeof lon !== "number" ||
    !startDate ||
    !endDate
  ) {
    return new Response(
      JSON.stringify({ error: "Missing lat/lon/startDate/endDate" }),
      { status: 400, headers: { "Content-Type": "application/json" } },
    );
  }

  const base = "https://api.open-meteo.com/v1/forecast";
  const hourly = [
    "temperature_2m",
    "wind_speed_10m",
    "wind_gusts_10m",
    "precipitation_probability",
    "cloud_cover",
    "pressure_msl",
  ].join(",");

  const forecastUrl =
    `${base}?latitude=${lat}&longitude=${lon}&hourly=${hourly}&daily=sunrise,sunset&timezone=auto&start_date=${startDate}&end_date=${endDate}`;
  const IPGEO_KEY = "bba731713f5543e287f6848f8a1502be";
  const astroUrl = `https://api.ipgeolocation.io/astronomy?apiKey=${IPGEO_KEY}&lat=${lat}&long=${lon}&date=${startDate}`;

  const WORLD_TIDES_API_KEY = "a198676f-3b41-4d09-ad7c-6b8362af7f7a";
  const tideUrl = WORLD_TIDES_API_KEY
    ? `https://www.worldtides.info/api/v3?extremes&lat=${lat}&lon=${lon}&start=${startDate}&end=${endDate}&key=${WORLD_TIDES_API_KEY}`
    : null;

  try {
    const [forecastRes, astroRes, tideRes] = await Promise.all([
      fetch(forecastUrl),
      fetch(astroUrl),
      tideUrl ? fetch(tideUrl) : Promise.resolve(null),
    ]);

    if (!forecastRes.ok) throw new Error(`Forecast error ${forecastRes.status}`);

    // ✅ make astronomy optional
    let astronomy: any = null;
    if (astroRes.ok) {
      astronomy = await astroRes.json();
    } else {
      console.warn(`Astronomy API failed with status ${astroRes.status}`);
    }

    const forecast = await forecastRes.json();
    const tides = tideRes ? await (tideRes as Response).json() : null;

    // normalize hourly
    const hours = (forecast.hourly?.time ?? []).map((t: string, i: number) => ({
      time: t,
      temp_c: forecast.hourly.temperature_2m?.[i] ?? null,
      wind_kmh: forecast.hourly.wind_speed_10m?.[i] ?? null,
      gust_kmh: forecast.hourly.wind_gusts_10m?.[i] ?? null,
      precip_prob: forecast.hourly.precipitation_probability?.[i] ?? null,
      cloud: forecast.hourly.cloud_cover?.[i] ?? null,
      pressure_hpa: forecast.hourly.pressure_msl?.[i] ?? null,
    }));

    // normalize daily
    const daily = (forecast.daily?.time ?? []).map((d: string, i: number) => ({
      date: d,
      sunrise: forecast.daily.sunrise?.[i] ?? null,
      sunset: forecast.daily.sunset?.[i] ?? null,
    }));

    // ✅ normalize astronomy if available
    const astroDaily = astronomy
  ? [
      {
        date: astronomy.date ?? startDate,
        moon_phase: astronomy.moon_phase ?? null,
        moonrise: astronomy.moonrise ?? null,
        moonset: astronomy.moonset ?? null,
        sunrise: astronomy.sunrise ?? null,
        sunset: astronomy.sunset ?? null,
      },
    ]
  : [];

    // normalize tides
    let tideEvents: TideEvent[] = [];
    if (tides?.extremes) {
      tideEvents = tides.extremes.map((e: any) => ({
        time: e.date,
        type: e.type,
        height: e.height,
      }));
    }

    const payload = {
      lat,
      lon,
      startDate,
      endDate,
      hourly: hours,
      daily,
      astronomy: astroDaily,
      tides: tideEvents,
      source: {
        weather: "open-meteo.com",
        astronomy: astronomy ? "ipgeolocation.io" : "none",
        tides: WORLD_TIDES_API_KEY ? "worldtides.info" : "none",
      },
      generated_at: new Date().toISOString(),
    };

    console.log("Astronomy API response:", astronomy);

    return new Response(JSON.stringify(payload), {
      headers: {
        "Content-Type": "application/json",
        "Cache-Control": "max-age=3600",
      },
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});
