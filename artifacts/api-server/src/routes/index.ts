import { Router, type IRouter } from "express";
import healthRouter from "./health.js";
import licenseRouter from "./license.js";
import luaRouter from "./lua.js";

const router: IRouter = Router();

router.use(healthRouter);
router.use("/license", licenseRouter);
router.use("/lua", luaRouter);

export default router;
