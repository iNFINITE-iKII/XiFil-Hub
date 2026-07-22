import { Router, type IRouter } from "express";
import healthRouter from "./health.js";
import authRouter from "./auth.js";
import gamesRouter from "./games.js";
import keysRouter from "./keys.js";
import adminRouter from "./admin.js";
import licenseRouter from "./license.js";
import loaderRouter from "./loader.js";
import luaRouter from "./lua.js";

const router: IRouter = Router();

router.use(healthRouter);
router.use("/auth", authRouter);
router.use("/games", gamesRouter);
router.use("/keys", keysRouter);
router.use("/admin", adminRouter);
router.use("/license", licenseRouter);
router.use("/loader", loaderRouter);
router.use("/lua", luaRouter);

export default router;
